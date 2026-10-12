import re
import sys
import threading
import time
from typing import Any, Callable, Iterable, Optional

import anyio
from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError

from .config_manager import BLOCK_CONTAINS, BLOCK_EXACT, ConfigManager
from .paths import get_data_dir
from .quick_commands import get_quick_commands
from .rcon_client import (
    INSTANCE_CS2,
    INSTANCE_GENERIC,
    INSTANCE_MINECRAFT,
    INSTANCE_PALWORLD,
    INSTANCE_SQUAD,
    ProxyConfig,
    RconClient,
    RconError,
    ServerConfig,
)
from .server_manager import ServerManager


MAX_OUTPUT_CHARS = 60000

_STATUS_COMMAND = {
    INSTANCE_MINECRAFT: "list",
    INSTANCE_SQUAD: "ListPlayers",
    INSTANCE_CS2: "status",
    INSTANCE_PALWORLD: "Info",
    INSTANCE_GENERIC: "status",
}

_CHAINING_CHARS = ("\r", "\n", ";", "`")


def _normalize(command: str) -> str:
    return re.sub(r"\s+", " ", command.strip()).lower()


def _starts_with_word(normalized: str, entry: str) -> bool:
    return normalized == entry or normalized.startswith(entry + " ")


def _glob(entry: str) -> re.Pattern:
    return re.compile("^" + "".join(".*" if ch == "*" else re.escape(ch) for ch in entry) + "$")


def entry_matches(command: str, entry: str, mode: str) -> bool:
    normalized = _normalize(command)
    needle = _normalize(entry)
    if not needle:
        return False
    if "*" in needle:
        return _glob(needle).match(normalized) is not None
    if mode == BLOCK_CONTAINS:
        return needle in normalized
    if mode == BLOCK_EXACT:
        if " " in needle:
            return _starts_with_word(normalized, needle)
        return normalized.split(" ", 1)[0] == needle
    return normalized.startswith(needle)


def blocked_by(command: str, rules: Iterable[Any]) -> Optional[tuple[str, str]]:
    # 规则在 ConfigManager 里已归一化成 {"command", "mode"}，这里不再兜第二种形状
    for rule in rules:
        if entry_matches(command, rule["command"], rule["mode"]):
            return rule["command"], rule["mode"]
    return None


def _reject_chaining(text: str, what: str) -> None:
    # Source 系服务器把分号当命令分隔符，换行同理：不过滤就能用一条命令绕过禁止列表
    for ch in _CHAINING_CHARS:
        if ch in text:
            raise ToolError(
                f"{what} must not contain {ch!r}: chained commands bypass the forbidden command "
                "list. Send one command per call."
            )


def _policy_summary(config: ConfigManager) -> dict[str, Any]:
    entries = config.mcp_forbidden_commands
    return {
        "forbidden_commands": entries,
        "forbidden_count": len(entries),
        "how_it_works": (
            "Each forbidden entry carries its own match mode (prefix / contains / exact), chosen by "
            "the user per command; an entry containing * is globbed against the whole command. A "
            "matching command is refused, everything else runs. The list lives in YiQQ-Rcon > "
            "Settings > MCP and is read live from disk, so the user can add an entry while this "
            "session stays connected. Report a refusal to the user instead of rewriting the command "
            "to slip past the list."
        ),
    }


def _audit(message: str) -> None:
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}"
    try:
        with open(get_data_dir() / "mcp_audit.log", "a", encoding="utf-8") as handle:
            handle.write(line + "\n")
    except OSError:
        pass


class ConnectionPool:
    def __init__(self, proxy_provider: Optional[Callable[[], ProxyConfig]] = None):
        self._proxy_provider = proxy_provider or (lambda: ProxyConfig())
        self._clients: dict[str, RconClient] = {}
        self._proxies: dict[str, ProxyConfig] = {}
        self._locks: dict[str, threading.Lock] = {}
        self._guards = threading.Lock()

    def _lock_for(self, server_id: str) -> threading.Lock:
        with self._guards:
            lock = self._locks.get(server_id)
            if lock is None:
                lock = threading.Lock()
                self._locks[server_id] = lock
            return lock

    def is_connected(self, server_id: str) -> bool:
        with self._guards:
            client = self._clients.get(server_id)
        return bool(client and client.connected)

    def close(self, server_id: str) -> None:
        with self._guards:
            client = self._clients.pop(server_id, None)
            self._proxies.pop(server_id, None)
        if client is not None:
            try:
                client.disconnect()
            except Exception:
                pass

    def close_all(self) -> None:
        with self._guards:
            server_ids = list(self._clients)
        for server_id in server_ids:
            self.close(server_id)

    def execute(self, server: ServerConfig, command: str) -> str:
        # AI 客户端会并发发起 tool call，而同一条 RCON 连接上响应只按 req id 认领；
        # 并发执行时回包会被别的命令当成广播读走，双方都拿不到结果，所以一台服一条命令排队。
        proxy = self._proxy_provider()
        with self._lock_for(server.id):
            client = self._clients.get(server.id)
            if client is not None and self._proxies.get(server.id) != proxy:
                self.close(server.id)
                client = None
            if client is None or not client.connected:
                self.close(server.id)
                client = RconClient(server, proxy)
                try:
                    client.connect()
                except RconError as exc:
                    raise ToolError(f"Cannot reach {server.name} ({server.host}:{server.port}): {exc}")
                self._clients[server.id] = client
                self._proxies[server.id] = proxy
            try:
                return client.execute(command)
            except RconError as exc:
                # 不就地重发：失败时命令可能已经到达服务器，重试会二次执行
                self.close(server.id)
                raise ToolError(f"Command failed on {server.name}: {exc}")


def _reload_if_changed(servers: ServerManager, watch: dict) -> None:
    # AI 会话通常是长驻进程，而服务器列表由 GUI 写盘：不按文件变化重载，新加的服务器要重连才可见
    try:
        stamp = servers.path.stat().st_mtime_ns
    except OSError:
        return
    if watch.get("servers") == stamp:
        return
    watch["servers"] = stamp
    servers.load()


def _reload_config_if_changed(config: ConfigManager, watch: dict) -> None:
    try:
        stamp = config.path.stat().st_mtime_ns
    except OSError:
        return
    if watch.get("config") == stamp:
        return
    watch["config"] = stamp
    config.load()


def _resolve(servers: ServerManager, ref: str, watch: dict) -> ServerConfig:
    _reject_chaining(ref, "server")
    _reload_if_changed(servers, watch)
    wanted = ref.strip()
    if not wanted:
        raise ToolError("server must not be empty")
    for server in servers.all():
        if server.id == wanted:
            return server
    lowered = wanted.lower()
    by_name = [s for s in servers.all() if s.name.lower() == lowered]
    if len(by_name) == 1:
        return by_name[0]
    if len(by_name) > 1:
        raise ToolError(f"Multiple servers are named '{wanted}'; use the server id instead.")
    partial = [s for s in servers.all() if lowered in s.name.lower()]
    if len(partial) == 1:
        return partial[0]
    if len(partial) > 1:
        names = ", ".join(s.name for s in partial)
        raise ToolError(f"'{wanted}' is ambiguous between: {names}. Use a server id.")
    available = ", ".join(s.name for s in servers.all()) or "none configured"
    raise ToolError(f"Unknown server '{wanted}'. Configured servers: {available}")


def _pack(output: str) -> tuple[str, bool]:
    if len(output) <= MAX_OUTPUT_CHARS:
        return output, False
    return output[:MAX_OUTPUT_CHARS], True


def _placeholders(command: str) -> list[str]:
    return re.findall(r"<([^<>]+)>", command)


def build_server(
    config: ConfigManager,
    servers: ServerManager,
    pool: Optional[ConnectionPool] = None,
) -> tuple[MCPServer, ConnectionPool]:
    pool = pool or ConnectionPool(lambda: config.proxy)
    watch: dict = {}

    def _sync() -> None:
        _reload_if_changed(servers, watch)
        _reload_config_if_changed(config, watch)

    instructions = (
        "YiQQ-Rcon MCP server: manages game server consoles (Minecraft, Palworld, Squad, CS2 or "
        "any Source RCON server) over RCON. Credentials, SOCKS5 proxy and server list come from "
        "the local YiQQ-Rcon app, so passwords never travel through this protocol. Anything the "
        "user forbids in YiQQ-Rcon > Settings > MCP is refused; everything else runs. Check "
        "list_servers before acting, and report a refusal to the user instead of rewording the "
        "command to slip past the list."
    )
    app = MCPServer(name="yiQQ-rcon", instructions=instructions)

    @app.tool(
        name="list_servers",
        title="List servers",
        description="List the RCON servers configured in YiQQ-Rcon with their id, name, address, "
        "game type, live connection state, and the current forbidden command list.",
    )
    async def list_servers() -> dict[str, Any]:
        _sync()
        return {
            "policy": _policy_summary(config),
            "servers": [
                {
                    "id": s.id,
                    "name": s.name,
                    "host": s.host,
                    "port": s.port,
                    "game": s.instance_type,
                    "connected": pool.is_connected(s.id),
                }
                for s in servers.all()
            ],
        }

    @app.tool(
        name="server_status",
        title="Server status",
        description="Run the built-in status query for one server (Minecraft 'list', Palworld "
        "'Info', CS2 'status', Squad 'ListPlayers'). Still checked against the forbidden list.",
    )
    async def server_status(server: str) -> dict[str, Any]:
        target = _resolve(servers, server, watch)
        command = _STATUS_COMMAND.get(target.instance_type, "status")
        return await _run(app_command=command, target=target)

    @app.tool(
        name="run_command",
        title="Run RCON command",
        description="Send one raw RCON command to a server. Refused only when it matches an entry "
        "on the user's forbidden command list (see list_servers). One command per call, no "
        "chaining with ';', newline or backtick.",
    )
    async def run_command(server: str, command: str) -> dict[str, Any]:
        target = _resolve(servers, server, watch)
        _reject_chaining(command, "command")
        if not command.strip():
            raise ToolError("command must not be empty")
        return await _run(app_command=command.strip(), target=target)

    @app.tool(
        name="quick_commands",
        title="List quick command templates",
        description="List the curated command templates YiQQ-Rcon ships for that server's game, "
        "the arguments each one expects, and whether the user's forbidden list already blocks it.",
    )
    async def quick_commands(server: str) -> dict[str, Any]:
        _sync()
        target = _resolve(servers, server, watch)
        templates = []
        for item in get_quick_commands(target.instance_type):
            hit = blocked_by(item.command, config.mcp_forbidden_commands)
            templates.append(
                {
                    "name": item.label,
                    "template": item.command,
                    "arguments": _placeholders(item.command),
                    "blocked": hit is not None,
                    "matched": hit[0] if hit else None,
                    "matched_mode": hit[1] if hit else None,
                    "description": item.description,
                }
            )
        return {
            "server": target.name,
            "game": target.instance_type,
            "policy": _policy_summary(config),
            "commands": templates,
        }

    @app.tool(
        name="run_quick_command",
        title="Run quick command template",
        description="Fill one curated template and run it. Pass arguments positionally in the "
        "order the placeholders appear, e.g. name 'KickPlayer' with arguments "
        "['76561198000000000']. Same forbidden-list check as run_command.",
    )
    async def run_quick_command(
        server: str, name: str, arguments: Optional[list[str]] = None
    ) -> dict[str, Any]:
        target = _resolve(servers, server, watch)
        wanted = name.strip().lower()
        template = None
        for item in get_quick_commands(target.instance_type):
            if item.label.lower() == wanted:
                template = item
                break
        if template is None:
            raise ToolError(
                f"No quick command named '{name}' for game '{target.instance_type}'. "
                "Call quick_commands first to list what exists."
            )
        args = list(arguments or [])
        params = _placeholders(template.command)
        if len(args) != len(params):
            raise ToolError(
                f"Quick command '{template.label}' expects {len(params)} argument(s) "
                f"({', '.join(params) or 'none'}), got {len(args)}."
            )
        for value in args:
            _reject_chaining(value, "argument")
        cursor = iter(args)
        filled = re.sub(r"<[^<>]+>", lambda _: next(cursor), template.command)
        result = await _run(app_command=filled, target=target)
        result["name"] = template.label
        return result

    async def _run(app_command: str, target: ServerConfig) -> dict[str, Any]:
        _reload_config_if_changed(config, watch)
        hit = blocked_by(app_command, config.mcp_forbidden_commands)
        if hit is not None:
            entry, mode = hit
            _audit(f"DENY server={target.name} command={app_command} matched={entry} mode={mode}")
            raise ToolError(
                f"Command '{app_command}' is refused: it matches the forbidden entry '{entry}' "
                f"(match mode: {mode}) set by the user in YiQQ-Rcon > Settings > MCP. Tell the user "
                "which command was blocked; do not reword it to get around the list."
            )
        output = await anyio.to_thread.run_sync(lambda: pool.execute(target, app_command))
        text, truncated = _pack(output)
        _audit(f"OK server={target.name} command={app_command}")
        return {
            "server": target.name,
            "game": target.instance_type,
            "command": app_command,
            "truncated": truncated,
            "output": text,
        }

    return app, pool


def run_mcp_server(
    config: Optional[ConfigManager] = None, servers: Optional[ServerManager] = None
) -> int:
    config = config or ConfigManager()
    if not config.mcp_enabled:
        sys.stderr.write(
            "YiQQ-Rcon MCP is disabled. Turn it on in YiQQ-Rcon > Settings > MCP "
            "(or set \"mcp_enabled\": true in config.json), then reconnect the client.\n"
        )
        return 2
    servers = servers or ServerManager()
    app, pool = build_server(config, servers)
    forbidden = config.mcp_forbidden_commands
    _audit(f"START servers={len(servers.all())} forbidden={len(forbidden)}")
    sys.stderr.write(
        f"YiQQ-Rcon MCP ready: {len(servers.all())} server(s), "
        f"{len(forbidden)} forbidden command(s)\n"
    )
    if not forbidden:
        sys.stderr.write(
            "Warning: the forbidden command list is empty, so this session can run any RCON "
            "command. Add entries in YiQQ-Rcon > Settings > MCP.\n"
        )
    try:
        app.run(transport="stdio")
    except (KeyboardInterrupt, BrokenPipeError):
        pass
    finally:
        pool.close_all()
        _audit("STOP")
    return 0

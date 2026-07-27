from dataclasses import dataclass
from typing import List

from core.rcon_client import INSTANCE_GENERIC, INSTANCE_MINECRAFT, INSTANCE_SQUAD, INSTANCE_CS2, INSTANCE_PALWORLD


@dataclass
class QuickCommand:
    label: str
    command: str
    description: str = ""


MINECRAFT_COMMANDS: List[QuickCommand] = [
    QuickCommand("list", "list", "列出当前所有在线玩家，返回玩家数量与名称。无需参数，直接执行即可查看。示例：list"),
    QuickCommand("op", "op <player>", "授予指定玩家管理员权限（OP）。参数 player 为目标玩家名称，授权后该玩家可执行管理类命令。示例：op Steve"),
    QuickCommand("deop", "deop <player>", "移除指定玩家的管理员权限（OP）。参数 player 为目标玩家名称，权限移除后无法再执行管理命令。示例：deop Steve"),
    QuickCommand("kick", "kick <player>", "将指定玩家踢出服务器。参数 player 为目标玩家名称，被踢玩家仍可重新连接加入。示例：kick Steve"),
    QuickCommand("ban", "ban <player>", "封禁指定玩家，使其无法再次加入。参数 player 为目标玩家名称，封禁后加入黑名单。示例：ban Steve"),
    QuickCommand("pardon", "pardon <player>", "解除对指定玩家的封禁。参数 player 为目标玩家名称，执行后该玩家可重新加入。示例：pardon Steve"),
    QuickCommand("save-all", "save-all", "将世界数据保存到磁盘。无需参数，建议在停机或备份前执行以防数据丢失。示例：save-all"),
    QuickCommand("stop", "stop", "安全关闭服务器并保存世界。无需参数，执行后服务器优雅关闭，请提前通知玩家。示例：stop"),
    QuickCommand("whitelist add", "whitelist add <player>", "将玩家添加到白名单。参数 player 为目标玩家名称，添加后可在白名单模式下加入。示例：whitelist add Steve"),
    QuickCommand("whitelist remove", "whitelist remove <player>", "将玩家从白名单移除。参数 player 为目标玩家名称，移除后将无法在白名单模式下加入。示例：whitelist remove Steve"),
    QuickCommand("gamemode", "gamemode <mode> <player>", "设置玩家游戏模式。参数 mode 可选 survival/creative/adventure/spectator；参数 player 为目标玩家名称，省略则作用于自身。示例：gamemode creative Steve"),
    QuickCommand("give", "give <player> <item>", "给予玩家指定物品。参数 player 为目标玩家名称，参数 item 为物品标识符，可附加数量与数据标签。示例：give Steve minecraft:diamond 64"),
    QuickCommand("tp", "tp <player> <target>", "将玩家传送到目标位置。参数 player 为要传送的玩家，参数 target 可为目标玩家名称或 x y z 坐标。示例：tp Steve Alex"),
    QuickCommand("time day", "time set day", "将游戏时间设置为白天（1000 刻）。无需参数，执行后世界立即变为白天。示例：time set day"),
    QuickCommand("time night", "time set night", "将游戏时间设置为夜晚（13000 刻）。无需参数，执行后世界立即变为夜晚并生成怪物。示例：time set night"),
    QuickCommand("weather clear", "weather clear", "将天气设置为晴天。无需参数，执行后停止降雨或雷暴。示例：weather clear"),
    QuickCommand("weather rain", "weather rain", "将天气设置为雨天。无需参数，执行后开始降雨但不伴随雷暴。示例：weather rain"),
    QuickCommand("weather thunder", "weather thunder", "将天气设置为雷暴。无需参数，执行后开始降雨并伴随雷电。示例：weather thunder"),
    QuickCommand("say", "say <message>", "向所有在线玩家广播一条消息。参数 message 为要发送的内容，以服务器身份显示。示例：say 服务器将于5分钟后重启"),
    QuickCommand("kill", "kill <player>", "强制击杀指定玩家。参数 player 为目标玩家名称，也可用 @a 表示所有玩家、@e 表示所有实体。示例：kill Steve"),
]


SQUAD_COMMANDS: List[QuickCommand] = [
    QuickCommand("ListPlayers", "ListPlayers", "列出当前所有在线玩家及其 ID。无需参数，返回玩家名称、Steam ID 及所在队伍。示例：ListPlayers"),
    QuickCommand("AdminListPlayers", "AdminListPlayers", "管理员视角列出在线玩家详细信息。无需参数，相比 ListPlayers 提供更完整的管理信息。示例：AdminListPlayers"),
    QuickCommand("AdminKick", "AdminKick <player> <reason>", "踢出指定玩家并附带原因。参数 player 为玩家 ID 或名称，参数 reason 为踢出原因。示例：AdminKick 12345 恶意行为"),
    QuickCommand("AdminBan", "AdminBan <player> <duration> <reason>", "封禁玩家。参数 player 为玩家 ID，参数 duration 为时长（1h/1d/permanent），参数 reason 为封禁原因。示例：AdminBan 12345 1d 使用外挂"),
    QuickCommand("AdminBroadcast", "AdminBroadcast <message>", "向全服玩家广播一条消息。参数 message 为要广播的内容，显示在所有玩家屏幕上方。示例：AdminBroadcast 服务器即将维护"),
    QuickCommand("AdminWarn", "AdminWarn <player> <message>", "向指定玩家发送警告消息。参数 player 为玩家 ID，参数 message 为警告内容，显示在玩家屏幕上。示例：AdminWarn 12345 请遵守游戏规则"),
    QuickCommand("AdminRestartMatch", "AdminRestartMatch", "立即重启当前对局。无需参数，执行后当前对局重置开始，请提前通知玩家。示例：AdminRestartMatch"),
    QuickCommand("AdminEndMatch", "AdminEndMatch", "立即结束当前对局。无需参数，执行后当前对局结束并进入下一局。示例：AdminEndMatch"),
    QuickCommand("AdminSetNextLayer", "AdminSetNextLayer <layer>", "设置下一局使用的兵种/载具层。参数 layer 为层标识符，对局结束后生效。示例：AdminSetNextLayer AlBasrah_AAS_v1"),
    QuickCommand("AdminSetNextMap", "AdminSetNextMap <map>", "设置下一张地图。参数 map 为地图标识符，当前对局结束后切换到该地图。示例：AdminSetNextMap AlBasrah"),
    QuickCommand("AdminChangeLayer", "AdminChangeLayer <layer>", "立即切换当前对局的层。参数 layer 为层标识符，执行后立即加载指定层并中断当前对局。示例：AdminChangeLayer AlBasrah_AAS_v1"),
    QuickCommand("AdminForceTeamChange", "AdminForceTeamChange <player>", "强制将玩家切换到对方阵营。参数 player 为玩家 ID，执行后玩家立即更换队伍。示例：AdminForceTeamChange 12345"),
    QuickCommand("AdminDemoteCommander", "AdminDemoteCommander <player>", "撤销指定玩家的指挥官身份。参数 player 为玩家 ID，执行后该玩家不再担任指挥官。示例：AdminDemoteCommander 12345"),
    QuickCommand("AdminDisbandSquad", "AdminDisbandSquad <team> <squad>", "解散指定队伍中的指定小队。参数 team 为队伍编号，参数 squad 为小队编号。示例：AdminDisbandSquad 1 2"),
    QuickCommand("AdminSetMaxNumPlayers", "AdminSetMaxNumPlayers <num>", "设置服务器最大玩家数。参数 num 为最大玩家数量，超过此数量新玩家无法加入。示例：AdminSetMaxNumPlayers 78"),
    QuickCommand("AdminSetServerPassword", "AdminSetServerPassword <password>", "设置服务器加入密码。参数 password 为密码字符串，设置后玩家需输入密码才能加入。示例：AdminSetServerPassword mypass123"),
    QuickCommand("AdminSlomo", "AdminSlomo <speed>", "设置游戏时间流速倍率。参数 speed 为倍率数值，1 为正常速度，0.5 为半速，2 为双倍速。示例：AdminSlomo 0.5"),
    QuickCommand("AdminSetFogOfWar", "AdminSetFogOfWar <true|false>", "开启或关闭战争迷雾。参数 true 开启迷雾限制视野，参数 false 关闭迷雾全图可见。示例：AdminSetFogOfWar false"),
]


CS2_COMMANDS: List[QuickCommand] = [
    QuickCommand("status", "status", "显示服务器状态信息，包括当前地图、玩家列表及其 Steam ID 与延迟。无需参数。示例：status"),
    QuickCommand("users", "users", "列出所有在线玩家的详细用户 ID。无需参数，返回 userid 与 Steam ID 对照表。示例：users"),
    QuickCommand("kick", "kick <name>", "按名称踢出指定玩家。参数 name 为目标玩家名称，被踢玩家可重新连接。示例：kick Steve"),
    QuickCommand("kickid", "kickid <userid>", "按用户 ID 踢出指定玩家。参数 userid 为目标玩家 ID，可通过 users 命令查询。示例：kickid 3"),
    QuickCommand("banid", "banid <minutes> <userid>", "按用户 ID 封禁玩家。参数 minutes 为封禁时长（0 为永久），参数 userid 为目标玩家 ID。示例：banid 60 3"),
    QuickCommand("say", "say <message>", "向所有在线玩家发送聊天消息。参数 message 为消息内容，以服务器身份显示在聊天框。示例：say 服务器将于5分钟后重启"),
    QuickCommand("changelevel", "changelevel <map>", "切换当前地图。参数 map 为地图名称，执行后所有玩家将加载新地图。示例：changelevel de_dust2"),
    QuickCommand("map", "map <map>", "加载指定地图并重新开始。参数 map 为地图名称，相比 changelevel 会完全重置。示例：map de_mirage"),
    QuickCommand("mp_restartgame", "mp_restartgame <seconds>", "在指定秒数后重启当前对局。参数 seconds 为延迟秒数，执行后比分清零并重新开始。示例：mp_restartgame 5"),
    QuickCommand("mp_pause_match", "mp_pause_match", "暂停当前比赛。无需参数，执行后比赛暂停，可在竞技模式中使用。示例：mp_pause_match"),
    QuickCommand("mp_unpause_match", "mp_unpause_match", "恢复已暂停的比赛。无需参数，执行后比赛继续进行。示例：mp_unpause_match"),
    QuickCommand("mp_warmup_end", "mp_warmup_end", "立即结束热身阶段并开始正式比赛。无需参数，执行后跳过剩余热身时间。示例：mp_warmup_end"),
    QuickCommand("mp_endmatch", "mp_endmatch", "立即结束当前比赛。无需参数，执行后比赛结束并显示结算画面。示例：mp_endmatch"),
    QuickCommand("bot_add", "bot_add", "向服务器添加一个机器人玩家。无需参数，机器人将自动加入人数较少的队伍。示例：bot_add"),
    QuickCommand("bot_kick", "bot_kick", "踢出所有机器人玩家。无需参数，执行后移除服务器上全部机器人。示例：bot_kick"),
    QuickCommand("sv_password", "sv_password <password>", "设置服务器加入密码。参数 password 为密码字符串，设置后玩家需输入密码才能加入。示例：sv_password mypass123"),
    QuickCommand("mp_maxrounds", "mp_maxrounds <rounds>", "设置比赛最大回合数。参数 rounds 为回合数，达到后比赛结束。示例：mp_maxrounds 30"),
    QuickCommand("sv_cheats", "sv_cheats <0|1>", "开启或关闭作弊模式。参数 1 开启（允许 noclip 等指令），参数 0 关闭。示例：sv_cheats 1"),
    QuickCommand("mp_friendlyfire", "mp_friendlyfire <0|1>", "开启或关闭友军伤害。参数 1 开启（队友可互相伤害），参数 0 关闭。示例：mp_friendlyfire 0"),
]


PALWORLD_COMMANDS: List[QuickCommand] = [
    QuickCommand("Info", "Info", "显示服务器基本信息，包括服务器名称、版本及当前在线人数。无需参数。示例：Info"),
    QuickCommand("ShowPlayers", "ShowPlayers", "列出当前所有在线玩家及其 Steam ID。无需参数，返回玩家名称与 Steam 64 位 ID。示例：ShowPlayers"),
    QuickCommand("KickPlayer", "KickPlayer <SteamID>", "踢出指定玩家。参数 SteamID 为目标玩家的 Steam 64 位 ID，可通过 ShowPlayers 查询，被踢玩家可重新连接。示例：KickPlayer 76561198000000000"),
    QuickCommand("BanPlayer", "BanPlayer <SteamID>", "封禁指定玩家使其无法再次加入。参数 SteamID 为目标玩家的 Steam 64 位 ID，封禁后加入黑名单。示例：BanPlayer 76561198000000000"),
    QuickCommand("Broadcast", "Broadcast <Message>", "向全服玩家广播一条消息。参数 Message 为消息内容，显示在所有在线玩家屏幕上方。示例：Broadcast 服务器将于5分钟后重启"),
    QuickCommand("Save", "Save", "立即保存世界数据到磁盘。无需参数，建议在停机或备份前执行以防数据丢失。示例：Save"),
    QuickCommand("Shutdown", "Shutdown <Seconds> <Message>", "在指定秒数后关闭服务器并广播提示。参数 Seconds 为倒计时秒数，参数 Message 为关服提示消息。示例：Shutdown 300 服务器将在5分钟后关闭"),
    QuickCommand("DoExit", "DoExit", "强制立即关闭服务器，不保存也不提示玩家。无需参数，紧急情况使用，正常关服请使用 Shutdown。示例：DoExit"),
]


QUICK_COMMAND_MAP = {
    INSTANCE_MINECRAFT: MINECRAFT_COMMANDS,
    INSTANCE_SQUAD: SQUAD_COMMANDS,
    INSTANCE_CS2: CS2_COMMANDS,
    INSTANCE_PALWORLD: PALWORLD_COMMANDS,
    INSTANCE_GENERIC: [],
}


def get_quick_commands(instance_type: str) -> List[QuickCommand]:
    return QUICK_COMMAND_MAP.get(instance_type, [])

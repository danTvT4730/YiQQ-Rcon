.pragma library

function tr(i18n, key) {
    if (!i18n || !i18n.strings)
        return key
    return i18n.strings[key] || key
}

function trFmt(i18n, key, args) {
    if (!i18n || !i18n.strings)
        return key
    var str = i18n.strings[key] || key
    if (!args)
        return str
    return str.replace(/\{(\w+)\}/g, function(match, k) {
        return args[k] !== undefined ? String(args[k]) : match
    })
}

function pageIndex(page) {
    switch (page) {
        case "select": return 0
        case "logs": return 1
        case "console": return 2
        case "about": return 3
        case "settings": return 4
        default: return 0
    }
}

function colorForLevel(i18n, level, dark) {
    if (level === "success") return dark ? "#10b981" : "#059669"
    if (level === "warning") return dark ? "#eab308" : "#ca8a04"
    if (level === "error") return dark ? "#ef4444" : "#dc2626"
    if (level === "command") return dark ? "#5eead4" : "#0d9488"
    if (level === "broadcast") return dark ? "#eab308" : "#ca8a04"
    if (level === "meta") return dark ? "#6b7280" : "#9ca3af"
    return dark ? "#e4e7eb" : "#1a1a1a"
}

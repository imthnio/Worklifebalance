import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case en
    case es
    case ja

    var id: String { rawValue }

    /// Language names are always shown in their own language
    var nativeName: String {
        switch self {
        case .system: return L10n.shared.t("settings.languageSystem")
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .en: return "English"
        case .es: return "Español"
        case .ja: return "日本語"
        }
    }

    static func fromSystem() -> AppLanguage {
        for code in Locale.preferredLanguages {
            let lower = code.lowercased()
            if lower.hasPrefix("zh") {
                if lower.contains("hant") || lower.contains("-tw") ||
                    lower.contains("-hk") || lower.contains("-mo") {
                    return .zhHant
                }
                return .zhHans
            }
            if lower.hasPrefix("ja") { return .ja }
            if lower.hasPrefix("es") { return .es }
            if lower.hasPrefix("en") { return .en }
        }
        return .en
    }
}

class L10n: ObservableObject {
    static let shared = L10n()

    @AppStorage("appLanguage") var language: AppLanguage = .system {
        willSet { objectWillChange.send() }
    }

    var effectiveLanguage: AppLanguage {
        language == .system ? AppLanguage.fromSystem() : language
    }

    func t(_ key: String) -> String {
        let lang = effectiveLanguage
        return translations[lang]?[key] ?? translations[.en]?[key] ?? key
    }

    func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }
}

private let translations: [AppLanguage: [String: String]] = [
    .zhHans: [
        "start": "开始",
        "stop": "停止",
        "pause": "暂停",
        "resume": "继续",
        "reset": "重新开始",
        "paused": "已暂停",
        "tab.timer": "计时",
        "tab.settings": "设置",
        "tab.shortcuts": "快捷键",
        "tab.sounds": "声音",
        "timer.workLength": "专注时长",
        "timer.minFormat": "%d 分钟",
        "timer.autoRestart": "结束后自动开始下一轮",
        "settings.language": "语言",
        "settings.languageSystem": "跟随系统",
        "settings.showTimer": "在菜单栏显示计时器",
        "settings.launchAtLogin": "登录时启动",
        "shortcut.startStop": "开始/停止",
        "shortcut.pauseResume": "暂停/继续",
        "shortcut.reset": "重新开始",
        "shortcut.togglePopover": "显示/隐藏面板",
        "shortcut.toggleTicking": "滴答声开关",
        "shortcut.recording": "请按下快捷键…",
        "shortcut.none": "未设置",
        "shortcut.hint": "点击录制，Esc 取消，Delete 清除",
        "shortcut.restoreDefaults": "恢复默认",
        "sounds.windup": "发条声",
        "sounds.ding": "叮",
        "sounds.ticking": "滴答声",
        "about": "关于",
        "quit": "退出",
        "notify.finished.title": "时间到",
        "notify.finished.body": "本轮专注已完成！",
    ],
    .zhHant: [
        "start": "開始",
        "stop": "停止",
        "pause": "暫停",
        "resume": "繼續",
        "reset": "重新開始",
        "paused": "已暫停",
        "tab.timer": "計時",
        "tab.settings": "設定",
        "tab.shortcuts": "快速鍵",
        "tab.sounds": "聲音",
        "timer.workLength": "專注時長",
        "timer.minFormat": "%d 分鐘",
        "timer.autoRestart": "結束後自動開始下一輪",
        "settings.language": "語言",
        "settings.languageSystem": "跟隨系統",
        "settings.showTimer": "在選單列顯示計時器",
        "settings.launchAtLogin": "登入時啟動",
        "shortcut.startStop": "開始/停止",
        "shortcut.pauseResume": "暫停/繼續",
        "shortcut.reset": "重新開始",
        "shortcut.togglePopover": "顯示/隱藏面板",
        "shortcut.toggleTicking": "滴答聲開關",
        "shortcut.recording": "請按下快速鍵…",
        "shortcut.none": "未設定",
        "shortcut.hint": "點擊錄製，Esc 取消，Delete 清除",
        "shortcut.restoreDefaults": "恢復預設",
        "sounds.windup": "發條聲",
        "sounds.ding": "叮",
        "sounds.ticking": "滴答聲",
        "about": "關於",
        "quit": "結束",
        "notify.finished.title": "時間到",
        "notify.finished.body": "本輪專注已完成！",
    ],
    .en: [
        "start": "Start",
        "stop": "Stop",
        "pause": "Pause",
        "resume": "Resume",
        "reset": "Restart",
        "paused": "Paused",
        "tab.timer": "Timer",
        "tab.settings": "Settings",
        "tab.shortcuts": "Shortcuts",
        "tab.sounds": "Sounds",
        "timer.workLength": "Focus length",
        "timer.minFormat": "%d min",
        "timer.autoRestart": "Start next round automatically",
        "settings.language": "Language",
        "settings.languageSystem": "System default",
        "settings.showTimer": "Show timer in menu bar",
        "settings.launchAtLogin": "Launch at login",
        "shortcut.startStop": "Start/Stop",
        "shortcut.pauseResume": "Pause/Resume",
        "shortcut.reset": "Restart",
        "shortcut.togglePopover": "Show/Hide panel",
        "shortcut.toggleTicking": "Toggle ticking",
        "shortcut.recording": "Press shortcut…",
        "shortcut.none": "None",
        "shortcut.hint": "Click to record, Esc to cancel, Delete to clear",
        "shortcut.restoreDefaults": "Restore defaults",
        "sounds.windup": "Windup",
        "sounds.ding": "Ding",
        "sounds.ticking": "Ticking",
        "about": "About",
        "quit": "Quit",
        "notify.finished.title": "Time's up",
        "notify.finished.body": "This focus session is complete!",
    ],
    .es: [
        "start": "Iniciar",
        "stop": "Detener",
        "pause": "Pausar",
        "resume": "Reanudar",
        "reset": "Reiniciar",
        "paused": "En pausa",
        "tab.timer": "Temporizador",
        "tab.settings": "Ajustes",
        "tab.shortcuts": "Atajos",
        "tab.sounds": "Sonidos",
        "timer.workLength": "Duración del enfoque",
        "timer.minFormat": "%d min",
        "timer.autoRestart": "Iniciar la siguiente ronda automáticamente",
        "settings.language": "Idioma",
        "settings.languageSystem": "Según el sistema",
        "settings.showTimer": "Mostrar temporizador en la barra de menús",
        "settings.launchAtLogin": "Abrir al iniciar sesión",
        "shortcut.startStop": "Iniciar/Detener",
        "shortcut.pauseResume": "Pausar/Reanudar",
        "shortcut.reset": "Reiniciar",
        "shortcut.togglePopover": "Mostrar/ocultar panel",
        "shortcut.toggleTicking": "Activar/desactivar tictac",
        "shortcut.recording": "Pulsa un atajo…",
        "shortcut.none": "Ninguno",
        "shortcut.hint": "Haz clic para grabar, Esc para cancelar, Supr para borrar",
        "shortcut.restoreDefaults": "Restaurar valores predeterminados",
        "sounds.windup": "Cuerda",
        "sounds.ding": "Campana",
        "sounds.ticking": "Tictac",
        "about": "Acerca de",
        "quit": "Salir",
        "notify.finished.title": "¡Se acabó el tiempo!",
        "notify.finished.body": "Has completado esta sesión de enfoque.",
    ],
    .ja: [
        "start": "開始",
        "stop": "停止",
        "pause": "一時停止",
        "resume": "再開",
        "reset": "リセット",
        "paused": "一時停止中",
        "tab.timer": "タイマー",
        "tab.settings": "設定",
        "tab.shortcuts": "ショートカット",
        "tab.sounds": "サウンド",
        "timer.workLength": "集中時間",
        "timer.minFormat": "%d 分",
        "timer.autoRestart": "終了後に次のラウンドを自動開始",
        "settings.language": "言語",
        "settings.languageSystem": "システムに従う",
        "settings.showTimer": "メニューバーにタイマーを表示",
        "settings.launchAtLogin": "ログイン時に起動",
        "shortcut.startStop": "開始/停止",
        "shortcut.pauseResume": "一時停止/再開",
        "shortcut.reset": "リセット",
        "shortcut.togglePopover": "パネルの表示/非表示",
        "shortcut.toggleTicking": "チクタク音のオン/オフ",
        "shortcut.recording": "キーを入力…",
        "shortcut.none": "未設定",
        "shortcut.hint": "クリックで記録、Esc でキャンセル、Delete で消去",
        "shortcut.restoreDefaults": "デフォルトに戻す",
        "sounds.windup": "ゼンマイ",
        "sounds.ding": "ベル",
        "sounds.ticking": "チクタク",
        "about": "このアプリについて",
        "quit": "終了",
        "notify.finished.title": "時間です",
        "notify.finished.body": "今回の集中が完了しました！",
    ],
]

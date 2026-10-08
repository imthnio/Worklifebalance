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
        "status.ready": "准备开始",
        "status.focusing": "专注中",
        "tab.timer": "计时",
        "tab.settings": "设置",
        "tab.shortcuts": "快捷键",
        "tab.sounds": "声音",
        "timer.workLength": "专注时长",
        "timer.minUnit": "分钟",
        "shortcut.quit": "退出",
        "notify.startNext": "开始下一轮",
        "notify.dismiss": "关闭",
        "timer.autoRestart": "结束后自动开始下一轮",
        "settings.general": "通用",
        "settings.language": "语言",
        "settings.languageSystem": "跟随系统",
        "settings.showTimer": "在菜单栏显示计时器",
        "settings.launchAtLogin": "登录时启动",
        "shortcut.startStop": "开始/停止",
        "shortcut.pauseResume": "暂停/继续",
        "shortcut.reset": "重新开始",
        "shortcut.togglePopover": "显示/隐藏面板",
        "shortcut.recording": "请按下快捷键…",
        "shortcut.none": "未设置",
        "shortcut.hint": "点击录制，Esc 取消，Delete 清除",
        "shortcut.restoreDefaults": "恢复默认",
        "sounds.alertFile": "提醒声音",
        "sounds.none": "无（只弹出提醒）",
        "sounds.remove": "移除声音",
        "sounds.volume": "音量",
        "sounds.missing": "找不到该文件或无法播放，到时不会出声",
        "sounds.choose": "选择…",
        "sounds.preview": "试听",
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
        "status.ready": "準備開始",
        "status.focusing": "專注中",
        "tab.timer": "計時",
        "tab.settings": "設定",
        "tab.shortcuts": "快速鍵",
        "tab.sounds": "聲音",
        "timer.workLength": "專注時長",
        "timer.minUnit": "分鐘",
        "shortcut.quit": "結束",
        "notify.startNext": "開始下一輪",
        "notify.dismiss": "關閉",
        "timer.autoRestart": "結束後自動開始下一輪",
        "settings.general": "一般",
        "settings.language": "語言",
        "settings.languageSystem": "跟隨系統",
        "settings.showTimer": "在選單列顯示計時器",
        "settings.launchAtLogin": "登入時啟動",
        "shortcut.startStop": "開始/停止",
        "shortcut.pauseResume": "暫停/繼續",
        "shortcut.reset": "重新開始",
        "shortcut.togglePopover": "顯示/隱藏面板",
        "shortcut.recording": "請按下快速鍵…",
        "shortcut.none": "未設定",
        "shortcut.hint": "點擊錄製，Esc 取消，Delete 清除",
        "shortcut.restoreDefaults": "恢復預設",
        "sounds.alertFile": "提醒聲音",
        "sounds.none": "無（只彈出提醒）",
        "sounds.remove": "移除聲音",
        "sounds.volume": "音量",
        "sounds.missing": "找不到該檔案或無法播放，到時不會出聲",
        "sounds.choose": "選擇…",
        "sounds.preview": "試聽",
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
        "status.ready": "Ready",
        "status.focusing": "Focusing",
        "tab.timer": "Timer",
        "tab.settings": "Settings",
        "tab.shortcuts": "Shortcuts",
        "tab.sounds": "Sounds",
        "timer.workLength": "Focus length",
        "timer.minUnit": "min",
        "shortcut.quit": "Quit",
        "notify.startNext": "Start next round",
        "notify.dismiss": "Close",
        "timer.autoRestart": "Start next round automatically",
        "settings.general": "General",
        "settings.language": "Language",
        "settings.languageSystem": "System default",
        "settings.showTimer": "Show timer in menu bar",
        "settings.launchAtLogin": "Launch at login",
        "shortcut.startStop": "Start/Stop",
        "shortcut.pauseResume": "Pause/Resume",
        "shortcut.reset": "Restart",
        "shortcut.togglePopover": "Show/Hide panel",
        "shortcut.recording": "Press shortcut…",
        "shortcut.none": "None",
        "shortcut.hint": "Click to record, Esc to cancel, Delete to clear",
        "shortcut.restoreDefaults": "Restore defaults",
        "sounds.alertFile": "Alert sound",
        "sounds.none": "None (banner only)",
        "sounds.remove": "Remove sound",
        "sounds.volume": "Volume",
        "sounds.missing": "File not found or can't be played; no sound will play",
        "sounds.choose": "Choose…",
        "sounds.preview": "Preview",
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
        "status.ready": "Listo",
        "status.focusing": "Enfocado",
        "tab.timer": "Temporizador",
        "tab.settings": "Ajustes",
        "tab.shortcuts": "Atajos",
        "tab.sounds": "Sonidos",
        "timer.workLength": "Duración del enfoque",
        "timer.minUnit": "min",
        "shortcut.quit": "Salir",
        "notify.startNext": "Iniciar otra ronda",
        "notify.dismiss": "Cerrar",
        "timer.autoRestart": "Iniciar la siguiente ronda automáticamente",
        "settings.general": "General",
        "settings.language": "Idioma",
        "settings.languageSystem": "Según el sistema",
        "settings.showTimer": "Mostrar temporizador en la barra de menús",
        "settings.launchAtLogin": "Abrir al iniciar sesión",
        "shortcut.startStop": "Iniciar/Detener",
        "shortcut.pauseResume": "Pausar/Reanudar",
        "shortcut.reset": "Reiniciar",
        "shortcut.togglePopover": "Mostrar/ocultar panel",
        "shortcut.recording": "Pulsa un atajo…",
        "shortcut.none": "Ninguno",
        "shortcut.hint": "Haz clic para grabar, Esc para cancelar, Supr para borrar",
        "shortcut.restoreDefaults": "Restaurar valores predeterminados",
        "sounds.alertFile": "Sonido de aviso",
        "sounds.none": "Ninguno (solo aviso)",
        "sounds.remove": "Quitar sonido",
        "sounds.volume": "Volumen",
        "sounds.missing": "No se encuentra el archivo o no se puede reproducir; no sonará nada",
        "sounds.choose": "Elegir…",
        "sounds.preview": "Escuchar",
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
        "status.ready": "準備完了",
        "status.focusing": "集中しています",
        "tab.timer": "タイマー",
        "tab.settings": "設定",
        "tab.shortcuts": "ショートカット",
        "tab.sounds": "サウンド",
        "timer.workLength": "集中時間",
        "timer.minUnit": "分",
        "shortcut.quit": "終了",
        "notify.startNext": "次のラウンドを開始",
        "notify.dismiss": "閉じる",
        "timer.autoRestart": "終了後に次のラウンドを自動開始",
        "settings.general": "一般",
        "settings.language": "言語",
        "settings.languageSystem": "システムに従う",
        "settings.showTimer": "メニューバーにタイマーを表示",
        "settings.launchAtLogin": "ログイン時に起動",
        "shortcut.startStop": "開始/停止",
        "shortcut.pauseResume": "一時停止/再開",
        "shortcut.reset": "リセット",
        "shortcut.togglePopover": "パネルの表示/非表示",
        "shortcut.recording": "キーを入力…",
        "shortcut.none": "未設定",
        "shortcut.hint": "クリックで記録、Esc でキャンセル、Delete で消去",
        "shortcut.restoreDefaults": "デフォルトに戻す",
        "sounds.alertFile": "通知音",
        "sounds.none": "なし（バナーのみ）",
        "sounds.remove": "音を削除",
        "sounds.volume": "音量",
        "sounds.missing": "ファイルが見つからないか再生できません。音は鳴りません",
        "sounds.choose": "選択…",
        "sounds.preview": "試聴",
        "quit": "終了",
        "notify.finished.title": "時間です",
        "notify.finished.body": "今回の集中が完了しました！",
    ],
]

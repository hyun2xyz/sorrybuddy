import AppKit

enum WarningDialog {
    @MainActor
    static func confirmEnable() -> Bool {
        let alert = NSAlert()
        alert.messageText = "닫힌 상태 작업 모드를 켤까요?"
        alert.informativeText = """
        이 모드는 맥북을 닫아도 작업이 계속되게 합니다.

        가방, 침대, 이불 위, 직사광선, 더운 장소에서는 사용하지 마세요. 전원 연결 상태에서 책상 위 테스트 용도로만 사용하세요.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "켜기")
        alert.addButton(withTitle: "취소")
        return alert.runModal() == .alertFirstButtonReturn
    }
}

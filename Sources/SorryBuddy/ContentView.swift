import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            modeSwitch
            statusCard
            betaNotice
            footerLinks
        }
        .padding(22)
        .frame(width: 520)
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.primaryText)
        .font(AppTheme.bodyFont)
        .onAppear {
            state.refresh()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            HeaderLogoMark(isActive: state.isClosedLidModeActive)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("SorryBuddy")
                    .font(AppTheme.titleFont)

                Text("맥북 닫힘 작업 모드 베타")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Text(state.isClosedLidModeActive ? "켜짐" : "대기")
                .font(AppTheme.badgeFont)
                .foregroundStyle(state.isClosedLidModeActive ? AppTheme.activeText : AppTheme.secondaryText)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(state.isClosedLidModeActive ? AppTheme.activeBackground : AppTheme.controlBackground)
                .clipShape(Capsule())
        }
    }

    private var modeSwitch: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("작업 모드")
                .font(AppTheme.sectionFont)

            HStack(spacing: 6) {
                Button {
                    if confirmEnable() {
                        state.enableClosedLidMode()
                    }
                } label: {
                    SwitchLabel(title: "켜기", subtitle: "뚜껑을 닫아도 계속 작업")
                }
                .buttonStyle(AppSwitchButtonStyle(isSelected: state.isClosedLidModeActive))
                .disabled(state.isBusy || state.isClosedLidModeActive)

                Button {
                    state.disableClosedLidMode()
                } label: {
                    SwitchLabel(title: "끄기", subtitle: "기본 잠자기 동작으로 복구")
                }
                .buttonStyle(AppSwitchButtonStyle(isSelected: !state.isClosedLidModeActive))
                .disabled(state.isBusy || !state.isClosedLidModeActive)
            }
            .padding(5)
            .background(AppTheme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var statusCard: some View {
        InfoCard(title: "현재 상태") {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "모드", value: state.isClosedLidModeActive ? "닫힌 상태 작업 모드가 켜져 있습니다." : "닫힌 상태 작업 모드가 꺼져 있습니다.")
                InfoRow(label: "전원", value: state.lastMessage)
                InfoRow(label: "창", value: "닫아도 앱은 메뉴바 새싹 아이콘에 남아 있습니다.")
                InfoRow(label: "종료", value: "메뉴바 새싹 아이콘에서 종료하기를 누르세요.")
            }
        }
    }

    private var betaNotice: some View {
        InfoCard(title: "베타 안내") {
            VStack(alignment: .leading, spacing: 7) {
                Text("베타 테스트 버전입니다. 사용 결과는 책임지지 않습니다. ദ്ദി( ᴖ ̫ᴖ )")
                    .foregroundStyle(AppTheme.primaryText)
                Text("클램쉘도 몇 시간씩 쓰는 걸 생각하면, 통풍만 지키면 큰 문제는 없지 않을까 생각합니다...")
                Text("그래도 가방, 침대, 이불 위, 더운 장소, 직사광선에서는 사용하지 마세요.")
                Text("배터리 10%가 되면 닫힌 상태 작업 모드가 자동으로 종료됩니다.")
            }
            .foregroundStyle(AppTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 14) {
            Button {
                state.refresh()
            } label: {
                Text("상태 새로고침")
            }
            .buttonStyle(LinkLikeButtonStyle())
            .disabled(state.isBusy)

            Text("GitHub 릴리즈에서 업데이트 확인")
                .foregroundStyle(AppTheme.linkText)
                .underline()

            Spacer()
        }
        .font(AppTheme.captionFont)
    }

    private func confirmEnable() -> Bool {
        WarningDialog.confirmEnable()
    }
}

private struct HeaderLogoMark: View {
    let isActive: Bool

    var body: some View {
        if let image = HeaderLogoImage.image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            SproutFaceMark(isActive: isActive)
                .padding(9)
                .background(AppTheme.iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

@MainActor
private enum HeaderLogoImage {
    static let image: NSImage? = {
        guard let url = Bundle.main.url(forResource: "SorryBuddyMenuBar", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.size = NSSize(width: 52, height: 52)
        return image
    }()
}

private enum AppTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let controlBackground = Color(nsColor: .quaternaryLabelColor).opacity(0.16)
    static let iconBackground = Color(nsColor: .quaternaryLabelColor).opacity(0.20)
    static let selectedBackground = Color(nsColor: .textBackgroundColor)
    static let activeBackground = Color(red: 0.82, green: 0.95, blue: 0.78)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
    static let activeText = Color(red: 0.18, green: 0.48, blue: 0.20)
    static let linkText = Color(nsColor: .linkColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.65)

    static let titleFont = Font.system(size: 24, weight: .semibold)
    static let sectionFont = Font.system(size: 13, weight: .semibold)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let captionFont = Font.system(size: 12, weight: .regular)
    static let badgeFont = Font.system(size: 11, weight: .semibold)
}

private struct SwitchLabel: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Text(subtitle)
                .font(AppTheme.captionFont)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct AppSwitchButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppTheme.border : Color.clear, lineWidth: 1)
            }
            .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 8, x: 0, y: 3)
            .opacity(isEnabled || isSelected ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        if isSelected {
            return AppTheme.primaryText
        }

        return isEnabled ? AppTheme.linkText : AppTheme.tertiaryText
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isSelected {
            return AppTheme.selectedBackground
        }

        return isPressed ? AppTheme.selectedBackground.opacity(0.6) : Color.clear
    }
}

private struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.sectionFont)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 42, alignment: .leading)
            Text(value)
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LinkLikeButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AppTheme.linkText : AppTheme.tertiaryText)
            .underline(isEnabled)
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

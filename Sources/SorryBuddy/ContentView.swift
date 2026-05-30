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
            footerAttribution
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

            Button {
                toggleClosedLidMode()
            } label: {
                LiquidModeSwitch(isOn: state.isClosedLidModeActive, isBusy: state.isBusy)
            }
            .buttonStyle(.plain)
            .disabled(state.isBusy)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: state.isClosedLidModeActive)
        }
    }

    private var statusCard: some View {
        InfoCard(
            title: "현재 상태",
            refreshAction: {
                state.refresh()
            },
            isRefreshDisabled: state.isBusy
        ) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "모드", value: state.isClosedLidModeActive ? "닫힌 상태 작업 모드가 켜져 있습니다." : "닫힌 상태 작업 모드가 꺼져 있습니다.")
                InfoRow(label: "전원", value: state.lastMessage)
                InfoRow(label: "창", value: "닫아도 앱은 메뉴바 새싹 아이콘에 남아 있습니다.")
                InfoRow(label: "종료", value: "메뉴바 새싹 아이콘에서 종료하기를 누르세요.")
            }
        }
    }

    private var betaNotice: some View {
        InfoCard {
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

    private var footerAttribution: some View {
        HStack {
            Link("@hyun2xyz", destination: URL(string: "https://www.instagram.com/hyun2xyz/")!)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.linkText)
                .underline()
            Spacer()
        }
    }

    private func confirmEnable() -> Bool {
        WarningDialog.confirmEnable()
    }

    private func toggleClosedLidMode() {
        if state.isClosedLidModeActive {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                state.disableClosedLidMode()
            }
        } else if confirmEnable() {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                state.enableClosedLidMode()
            }
        }
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
    static let activeBackground = Color.accentColor.opacity(0.16)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
    static let activeText = Color.accentColor
    static let linkText = Color(nsColor: .linkColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.65)
    static let glassStroke = Color(nsColor: .separatorColor).opacity(0.34)
    static let glassHighlight = Color.white.opacity(0.42)

    static let titleFont = Font.system(size: 24, weight: .semibold)
    static let sectionFont = Font.system(size: 13, weight: .semibold)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let captionFont = Font.system(size: 12, weight: .regular)
    static let badgeFont = Font.system(size: 11, weight: .semibold)
}

private struct LiquidModeSwitch: View {
    let isOn: Bool
    let isBusy: Bool

    var body: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 6
            let knobWidth = max((proxy.size.width - inset * 2) / 2, 0)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppTheme.glassStroke, lineWidth: 1)
                    }
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppTheme.glassHighlight, lineWidth: 1)
                            .blendMode(.softLight)
                    }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                    .frame(width: knobWidth, height: max(proxy.size.height - inset * 2, 0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isOn ? Color.accentColor.opacity(0.42) : AppTheme.glassStroke, lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 8)
                    .offset(x: isOn ? knobWidth : 0)
                    .padding(inset)

                HStack(spacing: 0) {
                    switchSide(
                        title: "꺼짐",
                        subtitle: "원상 복구",
                        isSelected: !isOn
                    )

                    switchSide(
                        title: "켜짐",
                        subtitle: "닫아도 계속 작업",
                        isSelected: isOn
                    )
                }
                .padding(.horizontal, 8)
            }
            .opacity(isBusy ? 0.56 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(height: 76)
    }

    private func switchSide(title: String, subtitle: String, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Text(subtitle)
                .font(AppTheme.captionFont)
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? AppTheme.primaryText : AppTheme.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
    }
}

private struct InfoCard<Content: View>: View {
    let title: String?
    let refreshAction: (() -> Void)?
    let isRefreshDisabled: Bool
    let content: Content

    init(
        title: String? = nil,
        refreshAction: (() -> Void)? = nil,
        isRefreshDisabled: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.refreshAction = refreshAction
        self.isRefreshDisabled = isRefreshDisabled
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if title != nil || refreshAction != nil {
                HStack(alignment: .center, spacing: 8) {
                    if let title {
                        Text(title)
                            .font(AppTheme.sectionFont)
                    }

                    Spacer()

                    if let refreshAction {
                        Button(action: refreshAction) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 26, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isRefreshDisabled ? AppTheme.tertiaryText : AppTheme.linkText)
                        .background(AppTheme.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .disabled(isRefreshDisabled)
                        .help("상태 새로고침")
                    }
                }
            }
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.glassStroke, lineWidth: 1)
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

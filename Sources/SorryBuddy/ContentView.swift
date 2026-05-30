import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            GlassBackdrop()
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.58)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                statusCard
                modeSwitch
                betaNotice
            }
            .padding(.horizontal, AppTheme.windowPadding)
            .padding(.top, AppTheme.titlebarInset)
            .padding(.bottom, AppTheme.windowPadding)
        }
        .overlay(alignment: .top) {
            titleBar
                .ignoresSafeArea(edges: .top)
        }
        .frame(width: 520)
        .foregroundStyle(AppTheme.primaryText)
        .font(AppTheme.bodyFont)
        .onAppear {
            state.refresh()
        }
    }

    private var titleBar: some View {
        Text("Hello Buddy")
            .font(AppTheme.titleFont)
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.titlebarHeight, alignment: .center)
            .allowsHitTesting(false)
    }

    private var modeSwitch: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("작업 모드")
                    .font(AppTheme.sectionFont)

                Spacer()

                Text(state.isClosedLidModeActive ? "켜짐" : "대기")
                    .font(AppTheme.badgeFont)
                    .foregroundStyle(state.isClosedLidModeActive ? AppTheme.activeText : AppTheme.secondaryText)
            }

            Button {
                toggleClosedLidMode()
            } label: {
                LiquidModeSwitch(isOn: state.isClosedLidModeActive, isBusy: state.isBusy)
            }
            .buttonStyle(.plain)
            .disabled(state.isBusy)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: state.isClosedLidModeActive)
        }
        .padding(AppTheme.cardPadding)
        .glassPanel(cornerRadius: 22)
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
            }
        }
    }

    private var betaNotice: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: AppTheme.noticeLineGap) {
                bodyText("제가 사용하려고 만든 베타 테스트 버전입니다.", color: AppTheme.primaryText)
                bodyText("사용 결과는 책임지지 않습니다. ദ്ദി( ᴖ ̫ᴖ )", color: AppTheme.primaryText)
                noticeBreak
                bodyText("겁주려는 건 아니고요...")
                bodyText("맥북 클램쉘 기능이 애초에 있으니까,")
                bodyText("통풍만 지키면 큰 문제는 없지 않을까 생각합니다.")
                bodyText("(저도 맨날써요)")
                noticeBreak
                bodyText("그래도 가방, 침대, 이불 위, 더운 장소,")
                bodyText("직사광선, 길게 사용은 하지마세요.")
                bodyText("이 앱은 배터리가 10%가 되면 자동으로 종료됩니다.")
                bodyText("CLI 환경을 사용하신다면 에이전트 규칙을")
                bodyText("배터리가 15프로가 되면 자동으로 커밋하고 정리되게 설정하세요.")
                attributionLine
            }
            .foregroundStyle(AppTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
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

    private func bodyText(_ value: String, color: Color = AppTheme.secondaryText) -> some View {
        Text(value)
            .foregroundStyle(color)
            .lineSpacing(AppTheme.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var noticeBreak: some View {
        Color.clear
            .frame(height: AppTheme.noticeParagraphGap)
    }

    private var attributionLine: some View {
        HStack(spacing: 4) {
            Text("그럼 잘 사용하시오")
                .lineSpacing(AppTheme.lineSpacing)
            Link("@hyun2xyz", destination: URL(string: "https://www.instagram.com/hyun2xyz/")!)
                .foregroundStyle(AppTheme.linkText)
                .underline()
        }
    }
}

private enum AppTheme {
    static let green = Color(nsColor: .systemGreen)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
    static let activeText = green
    static let linkText = green
    static let glassStroke = Color(nsColor: .separatorColor).opacity(0.38)
    static let glassHighlight = Color.white.opacity(0.54)
    static let glassShadow = Color.black.opacity(0.16)

    static let sectionFont = Font.system(size: 13, weight: .semibold)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let captionFont = Font.system(size: 12, weight: .regular)
    static let badgeFont = Font.system(size: 11, weight: .semibold)
    static let titleFont = Font.custom("Courier", fixedSize: 12)
    static let windowPadding: CGFloat = 18
    static let titlebarHeight: CGFloat = 30
    static let titlebarInset: CGFloat = 8
    static let cardSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 14
    static let lineSpacing: CGFloat = 4
    static let noticeLineGap: CGFloat = 5
    static let noticeParagraphGap: CGFloat = 3
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
                    .fill(.thinMaterial)
                    .frame(width: knobWidth, height: max(proxy.size.height - inset * 2, 0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isOn ? AppTheme.green.opacity(0.62) : AppTheme.glassStroke, lineWidth: 1)
                    }
                    .shadow(color: AppTheme.glassShadow, radius: 18, x: 0, y: 10)
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
        .padding(.horizontal, AppTheme.cardPadding)
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
                HStack(alignment: .top, spacing: 6) {
                    if let title {
                        Text(title)
                            .font(AppTheme.sectionFont)
                    }

                    if let refreshAction {
                        Button(action: refreshAction) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 18, height: 18)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isRefreshDisabled ? AppTheme.tertiaryText : AppTheme.green)
                        .disabled(isRefreshDisabled)
                        .help("상태 새로고침")
                    }

                    Spacer()
                }
            }
            content
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 22)
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
                .lineSpacing(AppTheme.lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GlassBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct GlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.glassStroke, lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.glassHighlight, lineWidth: 1)
                    .blendMode(.softLight)
            }
            .shadow(color: AppTheme.glassShadow, radius: 20, x: 0, y: 12)
    }
}

private extension View {
    func glassPanel(cornerRadius: CGFloat) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }
}

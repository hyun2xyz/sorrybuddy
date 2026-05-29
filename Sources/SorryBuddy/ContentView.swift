import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                SproutFaceMark(isActive: state.isClosedLidModeActive)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text("SorryBuddy")
                        .font(.title2.weight(.semibold))
                    Text(state.isClosedLidModeActive ? "닫힌 상태 작업 모드가 켜져 있습니다." : "닫힌 상태 작업 모드가 꺼져 있습니다.")
                        .foregroundStyle(.secondary)
                }
            }

            Text(state.lastMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                Text("책상 위 테스트 전용입니다.")
                    .font(.headline)
                Text("창을 닫아도 앱은 상단 메뉴바의 SB에 남아 있습니다. 완전히 끄려면 SB를 클릭하고 종료하기를 누르세요. 가방, 침대, 이불 위, 더운 장소, 직사광선에서는 사용하지 마세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button {
                    if confirmEnable() {
                        state.enableClosedLidMode()
                    }
                } label: {
                    Label("켜기", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.isBusy || state.isClosedLidModeActive)

                Button {
                    state.disableClosedLidMode()
                } label: {
                    Label("끄기", systemImage: "poweroff")
                        .frame(maxWidth: .infinity)
                }
                .disabled(state.isBusy || !state.isClosedLidModeActive)

                Button {
                    state.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("상태 새로고침")
                .disabled(state.isBusy)
            }
        }
        .padding(22)
        .frame(width: 460)
        .onAppear {
            state.refresh()
        }
    }

    private func confirmEnable() -> Bool {
        WarningDialog.confirmEnable()
    }
}

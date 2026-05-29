import Foundation

@MainActor
enum SharedAppState {
    static let state = AppState()
}

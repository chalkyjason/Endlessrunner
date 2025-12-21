import SwiftUI

@main
struct EndlessRunnerApp: App {
    @StateObject private var gameManager = GameManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .statusBarHidden()
        }
    }
}

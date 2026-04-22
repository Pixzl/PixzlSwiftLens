import SwiftUI
import PixzlSwiftLens

@main
struct PixzlSwiftLensDemoApp: App {
    init() {
        PixzlSwiftLensNetwork.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .pixzlSwiftLens()
        }
    }
}

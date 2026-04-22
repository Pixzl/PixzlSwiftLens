import SwiftUI
import OSLog

struct ContentView: View {
    @State private var status: String = "Shake the device or use Hardware → Shake to expand."
    @State private var ballast: [Data] = []

    private let log = Logger(subsystem: "com.pixzl.demo", category: "ui")

    var body: some View {
        NavigationStack {
            List {
                Section("Network") {
                    button("GET /todos/1", systemImage: "arrow.down.circle") { Task { await getRequest() } }
                    button("POST /posts", systemImage: "arrow.up.circle") { Task { await postRequest() } }
                    button("5 parallel requests", systemImage: "arrow.triangle.branch") { Task { await parallelRequests() } }
                    button("Force a 404", systemImage: "exclamationmark.triangle") { Task { await notFoundRequest() } }
                }
                Section("Logs") {
                    button("Logger.info",   systemImage: "info.circle")            { log.info("Hello from the demo app at \(Date())") }
                    button("Logger.notice", systemImage: "bell")                   { log.notice("Notice-level event") }
                    button("Logger.error",  systemImage: "xmark.octagon")          { log.error("Synthetic error for demo: \(UUID().uuidString)") }
                    button("Logger.fault",  systemImage: "bolt.trianglebadge.exclamationmark") { log.fault("Synthetic fault. The roof is on fire.") }
                }
                Section("Performance") {
                    button("Burn CPU (2s)", systemImage: "flame") { Task.detached(priority: .userInitiated) { burnCPU(seconds: 2) } }
                    button("Allocate 50 MB", systemImage: "memorychip") {
                        ballast.append(Data(count: 50 * 1024 * 1024))
                        status = "Holding \(ballast.count * 50) MB ballast."
                    }
                    button("Release ballast", systemImage: "trash") {
                        ballast.removeAll()
                        status = "Ballast released."
                    }
                }
                Section("Status") {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("PixzlSwiftLens Demo")
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("--auto-demo") {
                await runAutoDemo()
            }
        }
    }

    private func runAutoDemo() async {
        try? await Task.sleep(for: .milliseconds(1500))
        await getRequest()
        try? await Task.sleep(for: .milliseconds(900))
        await postRequest()
        try? await Task.sleep(for: .milliseconds(900))
        log.info("Hello from PixzlSwiftLens demo")
        log.notice("Notice-level event")
        log.error("Synthetic error: \(UUID().uuidString)")
        try? await Task.sleep(for: .milliseconds(800))
        Task.detached(priority: .userInitiated) { burnCPU(seconds: 1.5) }
        try? await Task.sleep(for: .milliseconds(2000))
        NotificationCenter.default.post(
            name: NSNotification.Name("com.pixzl.swiftlens.deviceShake"),
            object: nil
        )
    }

    private func button(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }

    // MARK: - Network actions

    private func getRequest() async {
        await fire(URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/todos/1")!))
    }

    private func postRequest() async {
        var req = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = #"{"title":"hi","body":"from demo","userId":1}"#.data(using: .utf8)
        await fire(req)
    }

    private func parallelRequests() async {
        await withTaskGroup(of: Void.self) { group in
            for id in 1...5 {
                group.addTask {
                    let url = URL(string: "https://jsonplaceholder.typicode.com/todos/\(id)")!
                    _ = try? await URLSession.shared.data(from: url)
                }
            }
        }
        status = "Fired 5 parallel requests."
    }

    private func notFoundRequest() async {
        await fire(URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/this-does-not-exist")!))
    }

    private func fire(_ request: URLRequest) async {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            status = "→ \(request.httpMethod ?? "GET") \(request.url?.path ?? "?")  \(code)  \(data.count)B"
        } catch {
            status = "✗ \(error.localizedDescription)"
        }
    }

    // MARK: - CPU burner (off main thread)

    nonisolated private func burnCPU(seconds: Double) {
        let end = Date().addingTimeInterval(seconds)
        var x: Double = 1.0
        while Date() < end {
            for _ in 0..<10_000 { x = (x * 1.0000001).truncatingRemainder(dividingBy: 1_000_000) }
        }
        _ = x
    }
}

#Preview {
    ContentView()
}

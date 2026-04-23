import SwiftUI

struct NetworkPanel: View {
    @Bindable var state: LensState
    @State private var query: String = ""

    var body: some View {
        List {
            ForEach(filtered.reversed()) { record in
                NavigationLink {
                    NetworkDetail(record: record)
                } label: {
                    NetworkRow(record: record)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: "URL or method")
        .overlay {
            if state.networkRecords.isEmpty {
                ContentUnavailableView("No requests yet",
                                       systemImage: "network",
                                       description: Text("Use URLSession(configuration: .pixzlSwiftLens()) or call PixzlSwiftLensNetwork.install()."))
            }
        }
    }

    private var filtered: [NetworkRecord] {
        guard !query.isEmpty else { return state.networkRecords }
        let q = query.lowercased()
        return state.networkRecords.filter {
            $0.url.absoluteString.lowercased().contains(q) || $0.method.lowercased().contains(q)
        }
    }
}

struct NetworkRow: View {
    let record: NetworkRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(record.statusEmoji).font(.body.bold())
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(record.method)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.15)))
                    Text(record.url.path.isEmpty ? record.url.absoluteString : record.url.path)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                HStack(spacing: 8) {
                    if let status = record.statusCode {
                        Text("\(status)").font(.caption).foregroundStyle(statusColor(status))
                    }
                    if let dur = record.duration {
                        Text("\(Int(dur * 1000)) ms").font(.caption).foregroundStyle(.secondary)
                    }
                    Text(record.url.host ?? "").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statusColor(_ s: Int) -> Color {
        (200..<300).contains(s) ? .green : .red
    }
}

struct NetworkDetail: View {
    let record: NetworkRecord
    @State private var showCopiedToast = false

    var body: some View {
        Form {
            Section("Request") {
                row("Method", record.method)
                row("URL", record.url.absoluteString)
                if let status = record.statusCode { row("Status", "\(status)") }
                if let dur = record.duration { row("Duration", "\(Int(dur * 1000)) ms") }
                if let err = record.errorDescription { row("Error", err) }
            }
            Section("Request Headers") {
                ForEach(record.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                    row(k, v)
                }
            }
            if let body = record.requestBody {
                Section(record.requestBodyTruncated ? "Request Body (truncated)" : "Request Body") {
                    bodyView(body)
                }
            }
            if let headers = record.responseHeaders, !headers.isEmpty {
                Section("Response Headers") {
                    ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                        row(k, v)
                    }
                }
            }
            if let body = record.responseBody {
                Section(record.responseBodyTruncated ? "Response Body (truncated)" : "Response Body") {
                    bodyView(body)
                }
            }
            Section {
                Button {
                    copyCURL()
                } label: {
                    Label(showCopiedToast ? "Copied!" : "Copy as cURL", systemImage: showCopiedToast ? "checkmark" : "doc.on.doc")
                }
            }
        }
        .navigationTitle(record.url.path)
        .lensInlineNavigationTitle()
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
        .font(.system(.caption, design: .monospaced))
    }

    @ViewBuilder
    private func bodyView(_ data: Data) -> some View {
        if let pretty = data.prettyPrintedJSONString() {
            Text(pretty)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
        } else if let text = String(data: data, encoding: .utf8) {
            Text(text)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
        } else {
            Text("\(data.count) bytes (binary)").foregroundStyle(.secondary)
        }
    }

    private func copyCURL() {
        let curl = CURLBuilder.build(record)
        #if canImport(UIKit)
        UIPasteboard.general.string = curl
        #endif
        showCopiedToast = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopiedToast = false
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif

extension Data {
    func prettyPrintedJSONString() -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else { return nil }
        return str
    }
}

import SwiftUI

struct LiveOutputView: View {
    @ObservedObject var cli: ClaudeCLI

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(cli.output.isEmpty ? "Waiting for output..." : cli.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(cli.output.isEmpty ? Theme.textTertiary : Theme.success.opacity(0.9))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                    if cli.isRunning {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Running...")
                                .font(Theme.captionMono)
                                .foregroundStyle(Theme.neonCyan)
                        }
                        .padding(.horizontal)
                        .id("bottom")
                    }
                }
            }
            .onChange(of: cli.output) {
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
}

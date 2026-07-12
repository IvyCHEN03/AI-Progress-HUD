import SwiftUI

struct HUDView: View {
    @ObservedObject var store: JobStore
    @State private var clock = Date()

    private var visibleJobs: [AIJobSnapshot] {
        store.presentedJobs.filter { !store.settings.hiddenProviders.contains($0.provider) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if !store.settings.collapsed {
                if visibleJobs.isEmpty { emptyState }
                else { jobList }
            }
        }
        .frame(width: 354)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.13), lineWidth: 1))
        .shadow(color: .black.opacity(0.36), radius: 22, y: 8)
        .opacity(store.settings.opacity)
        .environment(\.colorScheme, .dark)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { clock = $0 }
    }

    private var header: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle().fill(Color.cyan.opacity(0.18)).frame(width: 28, height: 28)
                Image(systemName: "waveform.path.ecg").foregroundStyle(.cyan)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("AI PROGRESS HUD").font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(1.05)
                Text("\(visibleJobs.filter { $0.state.isRunning }.count) 运行 · \(visibleJobs.filter { $0.state == .completed }.count) 待查看")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                if store.demoMode {
                    Text("DEMO").font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.yellow).padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.12), in: Capsule())
                }
                Circle().fill(store.browserReporting ? Color.green : Color.orange).frame(width: 7, height: 7)
                    .help(store.browserReporting ? "浏览器扩展正在上报" : "浏览器扩展尚未上报")
                Circle().fill(store.codexReporting ? Color.cyan : Color.gray).frame(width: 7, height: 7)
                    .help(store.codexReporting ? "Codex 本地任务已同步" : "未发现近期 Codex 任务")
            }
            Button { store.settings.collapsed.toggle() } label: {
                Image(systemName: store.settings.collapsed ? "chevron.down" : "chevron.up")
            }.buttonStyle(HUDIconButtonStyle())
            Button { store.requestSettings() } label: { Image(systemName: "slider.horizontal.3") }
                .buttonStyle(HUDIconButtonStyle())
            Button { store.requestQuit() } label: { Image(systemName: "xmark") }
                .buttonStyle(HUDIconButtonStyle())
                .help("退出 AI Progress HUD")
        }
        .padding(.horizontal, 13).padding(.vertical, 10)
    }

    private var jobList: some View {
        VStack(spacing: 8) {
            ForEach(AIProvider.allCases, id: \.self) { provider in
                let providerJobs = visibleJobs.filter { $0.provider == provider }
                if !providerJobs.isEmpty {
                    providerSection(provider, jobs: providerJobs)
                }
            }
        }
        .padding(.horizontal, 10).padding(.bottom, 11)
    }

    @ViewBuilder
    private func providerSection(_ provider: AIProvider, jobs: [AIJobSnapshot]) -> some View {
        let collapsed = store.settings.collapsedProviders.contains(provider)
        if jobs.count > 1 {
            Button {
                if collapsed { store.settings.collapsedProviders.remove(provider) }
                else { store.settings.collapsedProviders.insert(provider) }
            } label: {
                HStack {
                    Text(provider.label).font(.system(size: 10, weight: .bold))
                    Text("\(jobs.count)").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: collapsed ? "chevron.right" : "chevron.down").font(.caption2)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).padding(.horizontal, 5)
        }
        if !collapsed { ForEach(jobs) { job in JobBar(job: job, clock: clock, store: store) } }
    }

    private var emptyState: some View {
        VStack(spacing: 9) {
            Image(systemName: "sparkles.rectangle.stack").font(.title2).foregroundStyle(.cyan.opacity(0.8))
            Text("等待 AI 开始工作").font(.system(size: 12, weight: .semibold))
            VStack(alignment: .leading, spacing: 5) {
                DiagnosticLine(ok: store.serverOnline, text: store.serverOnline ? "本地服务正常" : "本地服务端口被占用")
                DiagnosticLine(ok: store.browserReporting, text: store.browserReporting ? "浏览器标签页已上报" : "扩展未上报：配对后刷新 AI 页面")
                DiagnosticLine(ok: store.codexReporting, text: store.codexReporting ? "Codex 任务已同步" : "等待 Codex 任务活动")
            }
        }.frame(maxWidth: .infinity).padding(.vertical, 22).padding(.bottom, 6)
    }
}

private struct DiagnosticLine: View {
    let ok: Bool
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(ok ? .green : .orange)
            Text(text).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
}

private struct JobBar: View {
    let job: AIJobSnapshot
    let clock: Date
    @ObservedObject var store: JobStore

    private var color: Color {
        switch job.state {
        case .idle: .gray
        case .thinking: .purple
        case .streaming: .cyan
        case .completed: .green
        case .attention: .orange
        case .error: .red
        case .disconnected: .gray
        }
    }

    var body: some View {
        Button { store.open(job) } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.16)).frame(width: 34, height: 34)
                    Text(job.provider.glyph).font(.system(size: 13, weight: .heavy)).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Text(job.provider.label).font(.system(size: 11, weight: .bold))
                        Text(job.sourceBadge)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(color.opacity(0.12), in: Capsule())
                            .foregroundStyle(color.opacity(0.9))
                        Text(job.pageTitle).lineLimit(1).font(.system(size: 10)).foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        Text(job.state.isRunning ? elapsedText : job.state.label)
                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(color)
                    }
                    ActivityTrack(color: color, state: job.state)
                }
            }
            .padding(8)
            .background(color.opacity(job.state == .completed ? 0.12 : 0.045))
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(color.opacity(job.state == .completed ? 0.6 : 0.16)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("标记为运行中") { store.setManualState(job, state: .thinking) }
            Button("标记为已完成") { store.setManualState(job, state: .completed) }
            Button("标记为空闲") { store.setManualState(job, state: .idle) }
        }
    }

    private var elapsedText: String {
        let total = Int(job.elapsed)
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct ActivityTrack: View {
    let color: Color
    let state: AIJobState
    @State private var travel = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                if state.isRunning {
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.15), color, .white.opacity(0.9), color.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * 0.48)
                        .offset(x: travel ? geometry.size.width * 0.55 : -geometry.size.width * 0.48)
                        .animation(.linear(duration: 1.35).repeatForever(autoreverses: false), value: travel)
                } else if state == .completed {
                    Capsule().fill(color).shadow(color: color.opacity(0.8), radius: 5)
                } else {
                    Capsule().fill(color.opacity(0.45)).frame(width: 22)
                }
            }
            .clipped()
        }
        .frame(height: 5)
        .onAppear { travel = true }
    }
}

private struct HUDIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .semibold)).frame(width: 25, height: 25)
            .background(Color.white.opacity(configuration.isPressed ? 0.14 : 0.07)).clipShape(Circle())
    }
}

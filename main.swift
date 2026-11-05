import AppKit
import SwiftUI
import ServiceManagement

// MARK: - Estado

final class Estado: ObservableObject {
    let defaults = UserDefaults.standard
    @Published var paciente: Paciente
    @Published var copiados: Set<String> = []
    @Published var ultimo: String?
    @Published var sexo: Sexo { didSet { defaults.set(sexo.rawValue, forKey: "sexo"); novo() } }
    @Published var pontuado: Bool { didSet { defaults.set(pontuado, forKey: "pontuado"); novo() } }
    var limpar: DispatchWorkItem?

    init() {
        let sx = Sexo(rawValue: UserDefaults.standard.string(forKey: "sexo") ?? "") ?? .aleatorio
        let pt = UserDefaults.standard.object(forKey: "pontuado") as? Bool ?? true
        sexo = sx
        pontuado = pt
        paciente = .novo(sexo: sx, pontuado: pt)
    }

    func novo() {
        paciente = .novo(sexo: sexo, pontuado: pontuado)
        copiados = []
        ultimo = nil
    }

    func copiar(_ rotulo: String, _ valor: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(valor, forType: .string)
        copiados.insert(rotulo)
        ultimo = rotulo
        limpar?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.ultimo = nil }
        limpar = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: w)
    }
}

// MARK: - Painel

struct Linha: View {
    let rotulo: String
    let valor: String
    @ObservedObject var estado: Estado
    @State private var hover = false

    var body: some View {
        let agora = estado.ultimo == rotulo
        let feito = estado.copiados.contains(rotulo)
        Button { estado.copiar(rotulo, valor) } label: {
            HStack(spacing: 8) {
                Text(rotulo)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 96, alignment: .leading)
                Text(valor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: agora ? "checkmark.circle.fill" : feito ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(agora ? Color.green : feito ? Color.secondary : Color.secondary.opacity(hover ? 1 : 0.4))
                    .frame(width: 16)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(agora ? Color.green.opacity(0.15) : hover ? Color.primary.opacity(0.07) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Copiar \(rotulo.lowercased())")
    }
}

struct Painel: View {
    @ObservedObject var estado: Estado
    var aoSair: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Paciente de teste").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { estado.novo() } label: { Label("Novo", systemImage: "arrow.clockwise") }
                    .help("Gerar outro paciente")
                Menu {
                    Picker("Sexo", selection: $estado.sexo) {
                        ForEach(Sexo.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("CPF com pontuação", isOn: $estado.pontuado)
                    Toggle("Abrir ao iniciar o Mac", isOn: Binding(
                        get: { SMAppService.mainApp.status == .enabled },
                        set: { on in try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }))
                    Divider()
                    Button("Sair", action: aoSair)
                } label: { Image(systemName: "gearshape") }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Opções")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            ForEach(estado.paciente.campos, id: \.0) { c in
                Linha(rotulo: c.0, valor: c.1, estado: estado)
            }

            Divider().padding(.vertical, 6)
            Button {
                estado.copiar("tudo", estado.paciente.texto)
            } label: {
                Label(estado.ultimo == "tudo" ? "Copiado" : "Copiar tudo", systemImage: estado.ultimo == "tudo" ? "checkmark" : "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .frame(width: 380)
    }
}

// Painel que não rouba o foco: o navegador continua ativo enquanto você copia.
final class PainelFlutuante: NSPanel {
    override var canBecomeKey: Bool { true }
}

// MARK: - App

final class App: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let estado = Estado()
    var painel: PainelFlutuante!

    func applicationDidFinishLaunching(_ n: Notification) {
        item.button?.image = NSImage(systemSymbolName: "person.text.rectangle", accessibilityDescription: "Paciente de teste")
        item.button?.target = self
        item.button?.action = #selector(alternar)
        item.button?.toolTip = "Paciente de teste: clique para abrir ou fechar"

        let host = NSHostingView(rootView: Painel(estado: estado, aoSair: { NSApp.terminate(nil) }))
        let fundo = NSVisualEffectView()
        fundo.material = .popover
        fundo.state = .active
        fundo.wantsLayer = true
        fundo.layer?.cornerRadius = 12
        fundo.layer?.masksToBounds = true
        host.translatesAutoresizingMaskIntoConstraints = false
        fundo.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: fundo.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: fundo.trailingAnchor),
            host.topAnchor.constraint(equalTo: fundo.topAnchor),
            host.bottomAnchor.constraint(equalTo: fundo.bottomAnchor),
        ])

        painel = PainelFlutuante(contentRect: .zero, styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: true)
        painel.contentView = fundo
        painel.isFloatingPanel = true
        painel.level = .statusBar
        painel.backgroundColor = .clear
        painel.isOpaque = false
        painel.hasShadow = true
        painel.hidesOnDeactivate = false
        painel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        if let demo = ProcessInfo.processInfo.environment["CPF_DEMO"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.mostrar()
                if demo == "copiando" {
                    for r in ["Nome", "CPF", "Nascimento"] {
                        if let v = self.estado.paciente.campos.first(where: { $0.0 == r })?.1 { self.estado.copiar(r, v) }
                    }
                    self.estado.limpar?.cancel()
                }
            }
        }
    }

    func mostrar() {
        guard let botao = item.button, let janela = botao.window else { return }
        let tam = painel.contentView!.fittingSize
        let ref = janela.convertToScreen(botao.convert(botao.bounds, to: nil))
        let tela = janela.screen?.visibleFrame ?? .zero
        var x = ref.midX - tam.width / 2
        x = min(max(x, tela.minX + 8), tela.maxX - tam.width - 8)
        painel.setFrame(NSRect(x: x, y: ref.minY - tam.height - 6, width: tam.width, height: tam.height), display: true)
        painel.orderFrontRegardless()
        botao.highlight(true)
    }

    @objc func alternar() {
        if painel.isVisible {
            painel.orderOut(nil)
            item.button?.highlight(false)
        } else {
            estado.novo()
            mostrar()
        }
    }
}

// --prints <pasta>: salva o painel em PNG, claro e escuro, sem precisar de captura de tela.
if let i = CommandLine.arguments.firstIndex(of: "--prints"), i + 1 < CommandLine.arguments.count {
    let pasta = URL(fileURLWithPath: CommandLine.arguments[i + 1])
    _ = NSApplication.shared
    for (nome, aparencia) in [("claro", NSAppearance.Name.aqua), ("escuro", .darkAqua)] {
        for copiando in [false, true] {
            let e = Estado()
            if copiando {
                for r in ["Nome", "CPF", "Nascimento"] {
                    if let v = e.paciente.campos.first(where: { $0.0 == r })?.1 { e.copiar(r, v) }
                }
                e.limpar?.cancel()
            }
            let host = NSHostingView(rootView: Painel(estado: e, aoSair: {}).background(Color(nsColor: .windowBackgroundColor)))
            host.appearance = NSAppearance(named: aparencia)
            let w = NSWindow(contentRect: NSRect(x: -5000, y: -5000, width: 380, height: 600), styleMask: [.borderless], backing: .buffered, defer: false)
            w.appearance = NSAppearance(named: aparencia)
            w.contentView = host
            host.layoutSubtreeIfNeeded()
            w.setContentSize(host.fittingSize)
            host.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
            host.cacheDisplay(in: host.bounds, to: rep)
            let arq = pasta.appendingPathComponent("painel-\(copiando ? "copiando" : "aberto")-\(nome).png")
            try! rep.representation(using: .png, properties: [:])!.write(to: arq)
            print(arq.path)
        }
    }
    exit(0)
}

if CommandLine.arguments.contains("--teste") {
    for _ in 0..<2 { print(Paciente.novo(sexo: .aleatorio, pontuado: true).texto, "\n") }
    exit(0)
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

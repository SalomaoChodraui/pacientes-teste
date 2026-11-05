import AppKit
import ServiceManagement

// Gera CPF com dígitos verificadores válidos. Nunca devolve sequência repetida (111.111.111-11).
func gerarCPF() -> [Int] {
    var d: [Int]
    repeat { d = (0..<9).map { _ in Int.random(in: 0...9) } } while Set(d).count == 1
    for n in [9, 10] {
        let soma = (0..<n).reduce(0) { $0 + d[$1] * (n + 1 - $1) }
        let r = soma % 11
        d.append(r < 2 ? 0 : 11 - r)
    }
    return d
}

func formatar(_ d: [Int], pontuado: Bool) -> String {
    let s = d.map(String.init).joined()
    guard pontuado else { return s }
    let c = Array(s)
    return "\(String(c[0..<3])).\(String(c[3..<6])).\(String(c[6..<9]))-\(String(c[9..<11]))"
}

final class App: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()
    var pontuado: Bool {
        get { UserDefaults.standard.object(forKey: "pontuado") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "pontuado") }
    }
    var ultimo = ""
    var timer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        mostrarIcone()
        item.button?.target = self
        item.button?.action = #selector(clique)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.button?.toolTip = "Clique: copia um CPF fake. Botão direito: opções."
    }

    func mostrarIcone() {
        item.button?.title = ""
        item.button?.image = NSImage(systemSymbolName: "person.text.rectangle", accessibilityDescription: "CPF fake")
    }

    @objc func clique() {
        let ev = NSApp.currentEvent
        if ev?.type == .rightMouseUp || ev?.modifierFlags.contains(.control) == true {
            abrirMenu()
        } else {
            copiar()
        }
    }

    func copiar() {
        ultimo = formatar(gerarCPF(), pontuado: pontuado)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(ultimo, forType: .string)
        item.button?.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Copiado")
        item.button?.imagePosition = .imageLeading
        item.button?.title = " " + ultimo
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in self?.mostrarIcone() }
    }

    func abrirMenu() {
        menu.removeAllItems()
        if !ultimo.isEmpty {
            let u = NSMenuItem(title: "Último: \(ultimo)", action: nil, keyEquivalent: "")
            u.isEnabled = false
            menu.addItem(u)
            menu.addItem(.separator())
        }
        let p = NSMenuItem(title: "Com pontuação", action: #selector(alternarPontuacao), keyEquivalent: "")
        p.state = pontuado ? .on : .off
        p.target = self
        menu.addItem(p)
        let l = NSMenuItem(title: "Abrir ao iniciar o Mac", action: #selector(alternarLogin), keyEquivalent: "")
        l.state = SMAppService.mainApp.status == .enabled ? .on : .off
        l.target = self
        menu.addItem(l)
        menu.addItem(.separator())
        let q = NSMenuItem(title: "Sair", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(q)
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc func alternarPontuacao() { pontuado.toggle() }

    @objc func alternarLogin() {
        let s = SMAppService.mainApp
        do { s.status == .enabled ? try s.unregister() : try s.register() }
        catch { NSSound.beep() }
    }
}

if CommandLine.arguments.contains("--teste") {
    for _ in 0..<5 { print(formatar(gerarCPF(), pontuado: true)) }
    exit(0)
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

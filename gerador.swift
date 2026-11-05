import Foundation

// MARK: - Geração

// CPF com dígitos verificadores válidos. Nunca devolve sequência repetida (111.111.111-11).
func gerarCPF(pontuado: Bool) -> String {
    var d: [Int]
    repeat { d = (0..<9).map { _ in Int.random(in: 0...9) } } while Set(d).count == 1
    for n in [9, 10] {
        let soma = (0..<n).reduce(0) { $0 + d[$1] * (n + 1 - $1) }
        let r = soma % 11
        d.append(r < 2 ? 0 : 11 - r)
    }
    let s = d.map(String.init).joined()
    guard pontuado else { return s }
    let c = Array(s)
    return "\(String(c[0..<3])).\(String(c[3..<6])).\(String(c[6..<9]))-\(String(c[9..<11]))"
}

func semAcento(_ s: String) -> String {
    s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .init(identifier: "pt_BR")).lowercased()
}

enum Sexo: String, CaseIterable { case aleatorio = "Aleatório", feminino = "Feminino", masculino = "Masculino" }

struct Paciente {
    let nome, cpf, sexo, nascimento, telefone, email, cep, rua, numero, complemento, bairro, cidade, uf: String

    static func novo(sexo pedido: Sexo, pontuado: Bool) -> Paciente {
        let fem = pedido == .aleatorio ? Bool.random() : pedido == .feminino
        let primeiro = (fem ? NOMES_F : NOMES_M).randomElement()!
        var sobre = Array(SOBRENOMES.shuffled().prefix(2))
        if Bool.random() { sobre = [sobre[1]] }
        let nome = ([primeiro] + sobre).joined(separator: " ")

        let hoje = Calendar.current.component(.year, from: Date())
        let ano = Int.random(in: (hoje - 85)...(hoje - 18))
        let mes = Int.random(in: 1...12)
        let dia = Int.random(in: 1...28)
        let nasc = String(format: "%02d/%02d/%04d", dia, mes, ano)

        let tel = String(format: "(11) 9%04d-%04d", Int.random(in: 6000...9999), Int.random(in: 0...9999))
        let email = "\(semAcento(primeiro)).\(semAcento(sobre.last!)).\(Int.random(in: 10...999))@example.com"

        let e = ENDERECOS.randomElement()!
        let comp = Bool.random() ? "Apto \(Int.random(in: 1...25))\(Int.random(in: 1...4))" : ""

        return Paciente(nome: nome, cpf: gerarCPF(pontuado: pontuado), sexo: fem ? "Feminino" : "Masculino",
                        nascimento: nasc, telefone: tel, email: email, cep: e.cep, rua: e.rua,
                        numero: String(Int.random(in: 10...1999)), complemento: comp,
                        bairro: e.bairro, cidade: e.cidade, uf: e.uf)
    }

    var campos: [(String, String)] {
        [("Nome", nome), ("CPF", cpf), ("Sexo", sexo), ("Nascimento", nascimento), ("Telefone", telefone),
         ("E-mail", email), ("CEP", cep), ("Rua", rua), ("Número", numero), ("Complemento", complemento),
         ("Bairro", bairro), ("Cidade", cidade), ("UF", uf)].filter { !$0.1.isEmpty }
    }

    var texto: String { campos.map { "\($0.0): \($0.1)" }.joined(separator: "\n") }
}

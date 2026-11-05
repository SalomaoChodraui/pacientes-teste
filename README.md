# CPF Fake

App de barra de menus para macOS que gera CPF com dígitos verificadores válidos e copia para a área de transferência. Serve para cadastrar paciente de teste em sistemas de saúde.

O número é válido só na matemática e pode coincidir com o CPF de alguém real. Usar apenas em teste.

## Uso

- Clique no ícone: gera e copia um CPF.
- Botão direito: último CPF gerado, alternar pontuação, abrir ao iniciar o Mac, sair.

## Instalar

Baixe o `CPF-Fake.zip` da última release, descompacte e arraste para Aplicativos. O app é assinado e notarizado, então abre sem aviso.

## Compilar

- `./build.sh` compila o binário universal (arm64 e x86_64) e instala em `~/Applications`.
- `./release.sh` faz o mesmo, assina com Developer ID, notariza e gera `CPF-Fake.zip`. Precisa do certificado Developer ID Application no Keychain e de uma credencial `notary` salva com `xcrun notarytool store-credentials`.

Requer macOS 13 ou mais novo.

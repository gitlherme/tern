<p align="center">
  <img src="brand/tern-icon.svg" width="128" height="128" alt="Ícone do Tern">
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="brand/tern-wordmark-light.svg">
    <img src="brand/tern-wordmark-dark.svg" height="56" alt="Tern">
  </picture>
</p>

<p align="center">
  <strong>Seletor de janelas para Mac, com o poder de esconder o que atrapalha.</strong><br>
  <kbd>⌥</kbd> <kbd>⇥</kbd> para trocar de janela · <kbd>⌫</kbd> para ocultar um app
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>Português</strong>
</p>

---

Tern é um seletor de janelas nativo para macOS que vive só na barra de menus, sem ícone no Dock. O atalho global abre um HUD para ciclar e focar janelas abertas — no espírito do [alt-tab.app](https://alt-tab.app), com um diferencial: você **oculta um app (ou uma janela)** e ele deixa de aparecer no seletor até você tirá-lo da lista.

Exemplo: cinco apps abertos, um na lista de exclusões, o atalho mostra só os outros quatro.

## Baixar

Baixe o **`Tern-x.y.z.dmg`** na [última release](https://github.com/gitlherme/vez/releases/latest), abra e arraste o Tern para **Aplicativos**.

O app ainda não é notarizado pela Apple, então o macOS bloqueia a primeira abertura. Abra o Tern uma vez, feche o aviso e vá em **Ajustes do Sistema › Privacidade e segurança › Abrir Mesmo Assim**. Ou rode:

```bash
xattr -dr com.apple.quarantine /Applications/Tern.app
```

Depois conceda Acessibilidade quando o Tern pedir e aperte **⌥⇥**.

## Recursos

- App de barra de menus (`LSUIElement`), Swift + SwiftUI/AppKit.
- Atalho global configurável (padrão **⌥⇥**). O HUD sobrepõe o app da frente e o atalho **não** dispara também no browser. Segure o modificador e toque a tecla outra vez para avançar; solte o modificador para focar a janela. **⇧⇥** volta. Clique, **⏎** e **esc** também funcionam.
- Exclusão por **bundle id** (caminho principal) e exclusão por janela (bundle id + título).
- Prévia de cada janela nos cards (com permissão de Gravação da tela).
- Interface em **português e inglês** (segue o idioma do macOS; outros idiomas caem no inglês).
- Persistência das exclusões e do atalho em `UserDefaults`.
- Ajustes para gravar o atalho, conceder Acessibilidade e adicionar/remover exclusões.

No seletor: **⌫** oculta o app da janela destacada; **⌥⌫** oculta só aquela janela.

## Requisitos

- macOS 13 Ventura ou posterior
- Xcode 15 ou posterior
- Um Apple ID (grátis) para assinar o app localmente

## Compilar e rodar

```bash
git clone https://github.com/gitlherme/vez.git
cd vez
open Tern.xcodeproj
```

No Xcode:

1. Escolha o scheme **Tern**.
2. Em **TARGETS › Tern › Signing & Capabilities**, marque *Automatically manage signing* e escolha seu **Personal Team**. Com uma assinatura estável, as permissões de Acessibilidade e Gravação da tela continuam valendo entre builds.
3. Rode (**⌘R**). O Tern aparece na barra de menus, não no Dock.

Pela linha de comando:

```bash
xcodebuild -project Tern.xcodeproj -scheme Tern -configuration Debug -destination 'platform=macOS' build
```

### Instalar para uso diário

**Product › Archive › Distribute App › Custom › Copy App** e mova o `Tern.app` para `/Applications`. Depois adicione-o em Ajustes do Sistema › Geral › Itens de início.

## Permissões

### Acessibilidade (obrigatória)

O macOS só deixa o Tern **listar títulos de janela** e **trazer a janela escolhida para a frente** com Acessibilidade ligada.

1. Rode o Tern pelo Xcode.
2. Pressione **⌥⇥** (ou o atalho que você gravou). Se a permissão estiver off, o HUD pede Acessibilidade.
3. Clique **Abrir Ajustes do Sistema** (ou **Pedir permissão** para o diálogo nativo).
4. Ajustes do Sistema → Privacidade e segurança → **Acessibilidade**.
5. Ative **Tern**. Se o Tern não aparecer, use o **+** e escolha `Tern.app` no DerivedData ou em Produtos do Xcode.
6. Volte ao Tern e use o atalho de novo.

Se você recompilar com outro caminho ou outra assinatura, o macOS trata como um app novo: desligue e ligue de novo o Tern na lista, ou remova e adicione outra vez.

Atalho direto (Ventura/Sonoma/Sequoia):

- `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
- `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility`

### Monitoramento de entrada (só se o atalho vazar)

Com Acessibilidade ligada o Tern instala um event tap e **engole** o atalho, para o ⌥⇥ não rodar também no browser. Na maioria dos macOS isso basta.

Se mesmo assim o app da frente reagir ao atalho, ligue **Monitoramento de entrada** para o Tern:

Ajustes do Sistema → Privacidade e segurança → **Monitoramento de entrada**.

- `x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent`

### Gravação da tela (prévias)

Os cards mostram uma **miniatura da janela**. O macOS exige Gravação da tela para isso. Sem a permissão o seletor **continua trocando de janela**; só a prévia some.

1. Em Ajustes do Tern, clique **Pedir permissão** (ou **Mostrar Tern.app no Finder**). Isso copia o app para `~/Applications/Tern.app` e seleciona no Finder.
2. Ajustes do Sistema → Privacidade e segurança → **Screen & System Audio Recording**.
3. O Tern **não entra sozinho** nessa lista. Clique no **+**, escolha `Tern.app` (em Aplicativos da sua pasta de usuário) ou arraste-o do Finder para a lista, e ligue o interruptor.
4. Barra de menus → **Sair**, depois rode de novo no Xcode (**⌘R**). A permissão nova só vale no próximo processo.

Com "Sign to Run Locally" (assinatura `adhoc`) cada rebuild muda o `cdhash` e o interruptor pode precisar ser religado. Assinar com o Personal Team evita isso.

- `x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`
- `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture`

## Uso

1. Conceda Acessibilidade. Para ver a prévia, conceda também Gravação da tela.
2. **⌥⇥** abre o seletor com a janela atual no índice 0 e a anterior no 1. Solte ⌥ para ir à anterior; ⇥ avança na recência. Minimizadas ficam no fim e restauram ao focar.
3. Continue com ⇥ / setas, solte ⌥ para focar, ou clique no card.
4. Para ocultar um app: Ajustes → Exclusões → **Adicionar app em execução…**, ou **⌫** no seletor.
5. Para ocultar só uma janela: **Adicionar janela aberta…** ou **⌥⌫**.
6. Menu da barra: Abrir seletor, Ajustes, Sair.

Não grave **⌘⇥**: o macOS reserva esse atalho para o seletor de aplicativos.

## Limitações conhecidas desta fatia

- A ordem é recência: janela atual → a anterior → demais usadas → minimizadas no fim.
- Exclusão de janela depende do título: se o título mudar, a janela volta a aparecer.
- Não substitui o ⌘⇥ do sistema.
- Não há sandbox: utilitários deste tipo precisam falar com as janelas dos outros apps.

## Estrutura

```
Tern.xcodeproj         projeto Xcode
Tern/
  TernApp.swift        entrada SwiftUI, sem Dock
  Localizable.xcstrings  textos da interface (pt-BR → en)
  AppModel.swift       estado, atalho, exclusões
  Models/              janela, exclusão, atalho
  Services/            AX windows, CG metadata, prévia, Carbon hotkey, persistência
  Views/               HUD, ajustes, barra de menus
brand/                 ícone, logotipo e variações
site/                  página de apresentação (HTML estático)
```

Bundle id: `dev.guilhermevieira.Tern`. Deployment: macOS 13+.

# Vez

Seletor de janelas nativo para macOS, só na barra de menus (sem ícone no Dock). O atalho global abre um HUD para ciclar e focar janelas abertas — no espírito do [alt-tab.app](https://alt-tab.app), com um diferencial: você **oculta um app (ou uma janela)** e ele deixa de aparecer no seletor até você tirá-lo da lista.

Exemplo: cinco apps abertos, um na lista de exclusões, o atalho mostra só os outros quatro.

Este repositório é um projeto Xcode completo (`Vez.xcodeproj`). Foi escrito para abrir e rodar num Mac; **não dá para compilar aqui em Linux**.

## O que esta fatia faz

- App de barra de menus (`LSUIElement`), Swift + SwiftUI/AppKit.
- Atalho global configurável (padrão **⌥⇥**). Segure o modificador e toque a tecla outra vez para avançar; solte o modificador para focar a janela. **⇧⇥** volta. Clique, **⏎** e **esc** também funcionam.
- Exclusão por **bundle id** (caminho principal) e exclusão por janela (bundle id + título).
- Persistência das exclusões e do atalho em `UserDefaults`.
- Ajustes para gravar o atalho, conceder Acessibilidade e adicionar/remover exclusões.
- Estados vazios: sem janelas (ou todas ocultas), lista de exclusões vazia, Acessibilidade desligada com CTA para os Ajustes do Sistema.

No seletor: **⌫** oculta o app da janela destacada; **⌥⌫** oculta só aquela janela.

## Requisitos

- macOS 13 Ventura ou posterior
- Xcode 15 ou posterior
- Conta Apple para assinar o app (ou “Sign to Run Locally”)

## Build / run on macOS

```bash
git clone <repo-url>
cd <repo>
open Vez.xcodeproj
```

In Xcode:

1. Select the **Vez** scheme.
2. Debug already uses **Sign to Run Locally** (no Apple Developer team required). To ship later, pick a Team in Signing & Capabilities.
3. Run (**⌘R**). The app appears in the menu bar as two overlapping rectangles, not in the Dock.

CLI (same machine, with Command Line Tools):

```bash
xcodebuild -project Vez.xcodeproj -scheme Vez -configuration Debug -destination 'platform=macOS' build
```

The `.app` lands under Xcode’s DerivedData. First launch from Xcode is the usual path, because Accessibility is granted to that exact binary.

## Permissões

### Acessibilidade (obrigatória)

O macOS só deixa o Vez **listar títulos de janela** e **trazer a janela escolhida para a frente** com Acessibilidade ligada.

1. Rode o Vez pelo Xcode.
2. Pressione **⌥⇥** (ou o atalho que você gravou). Se a permissão estiver off, o HUD pede Acessibilidade.
3. Clique **Abrir Ajustes do Sistema** (ou **Pedir permissão** para o diálogo nativo).
4. Ajustes do Sistema → Privacidade e segurança → **Acessibilidade**.
5. Ative **Vez**. Se o Vez não aparecer, use o **+** e escolha `Vez.app` no DerivedData ou em Produtos do Xcode.
6. Volte ao Vez e use o atalho de novo.

Se você recompilar com outro caminho ou outra assinatura, o macOS trata como um app novo: desligue e ligue de novo o Vez na lista, ou remova e adicione outra vez.

Atalho direto (Ventura/Sonoma/Sequoia):

- `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
- `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility`

### Monitoramento de entrada (não necessário nesta fatia)

O atalho global usa `RegisterEventHotKey` (Carbon), não um CGEvent tap. **Monitoramento de entrada / Input Monitoring não precisa estar ligado** para o padrão ⌥⇥.

Se no futuro o Vez passar a interceptar ⌘⇥ do sistema, aí sim essa permissão entra. O README documenta o caminho para quando isso acontecer:

Ajustes do Sistema → Privacidade e segurança → **Monitoramento de entrada**.

- `x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent`

### Gravação da tela

Esta fatia **não** pede Screen Recording: o seletor mostra ícone do app + título, sem thumbnail ao vivo. Isso evita uma terceira permissão no primeiro uso.

## Uso

1. Conceda Acessibilidade.
2. **⌥⇥** abre o seletor. A primeira batida destaca a janela imediatamente abaixo da atual (como Alt-Tab).
3. Continue com ⇥ / setas, solte ⌥ para focar, ou clique no card.
4. Para ocultar um app: Ajustes → Exclusões → **Adicionar app em execução…**, ou **⌫** no seletor.
5. Para ocultar só uma janela: **Adicionar janela aberta…** ou **⌥⌫**.
6. Menu da barra: Abrir seletor, Ajustes, Sair.

Não grave **⌘⇥**: o macOS reserva esse atalho para o seletor de aplicativos.

## Limitações conhecidas desta fatia

- Sem thumbnails ao vivo e sem pedir Screen Recording.
- A ordem das janelas segue a lista do CoreGraphics (frente → trás), não um histórico MRU sofisticado.
- Exclusão de janela depende do título: se o título mudar, a janela volta a aparecer.
- Não substitui o ⌘⇥ do sistema.
- Não há sandbox: utilitários deste tipo precisam falar com as janelas dos outros apps.

## Estrutura

```
Vez.xcodeproj          projeto Xcode
Vez/
  VezApp.swift         entrada SwiftUI, sem Dock
  AppModel.swift       estado, atalho, exclusões
  Models/              janela, exclusão, atalho
  Services/            CGWindowList, AX raise, Carbon hotkey, persistência
  Views/               HUD, ajustes, barra de menus
```

Bundle id: `dev.guilhermevieira.Vez`. Deployment: macOS 13+.

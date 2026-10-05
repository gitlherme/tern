# Plano de SEO e AEO do Tern

Outubro de 2026. Objetivo: quando alguém buscar no Google, ou perguntar a uma IA (ChatGPT, Perplexity, Gemini, Google AI Overviews, Claude), por um Alt+Tab para Mac, um alternador de janelas ou um jeito de esconder apps do alternador, o Tern aparecer e ser recomendado.

## Decisões já tomadas

- **Notarização:** não, por enquanto. O aviso na primeira abertura é um custo fixo que o resto do plano compensa (ajuda com capturas de tela, FAQ honesta). Reavaliar se o Tern ganhar tração: quanto mais tarde a troca de certificado, mais gente precisa conceder a Acessibilidade de novo.
- **H1 da home:** trocar por um com termo de busca; o slogan vira linha secundária.
- **Ordem:** revisar este plano antes de implementar.

## Resumo

Hoje o Tern é praticamente invisível para buscadores e IAs. O motivo principal não é falta de conteúdo, e sim três problemas concretos:

1. Um redirecionamento por JavaScript que provavelmente esconde a home em português do Google.
2. Nenhuma presença fora do próprio site.
3. Um nome que colide com outro app de Mac.

O plano tem quatro frentes: corrigir a base técnica, reescrever e ampliar o conteúdo do site em torno das buscas reais, colocar o Tern nos lugares de onde as IAs tiram recomendações, e medir.

## Diagnóstico

### No site (`site/`, servido pelo Vercel em tern.gitlher.me)

- **Redirecionamento por idioma.** A home em português redireciona para `/en/` via JavaScript quando `navigator.language` não começa com `pt`. O Googlebot rastreia a partir dos EUA e sem idioma definido, então muito provavelmente vê `/` como um redirecionamento para `/en/` e não indexa a versão em português. O Google recomenda não redirecionar automaticamente por idioma. O mesmo script está no changelog.
- **`hreflang` relativo.** As quatro páginas usam URLs relativas (`./`, `en/`); o Google só aceita URLs absolutas. As duas homes também não têm `canonical`.
- **Sem `robots.txt` e sem `sitemap.xml`.** Os dois respondem 404.
- **URLs duplicadas.** A mesma página responde em `/`, `/index.html`, `/en` e `/en/`. Em `/en` (sem barra), os links relativos quebram: "Changelog" leva para o changelog em português.
- **Sem Open Graph.** Links compartilhados no WhatsApp, Reddit, X ou Slack aparecem sem imagem e sem descrição bem formatada.
- **Sem dados estruturados.** Nada diz às máquinas que o Tern é um app gratuito para macOS, com versão, data e licença.
- **Textos sem os termos buscados.** Os títulos são bons de marca ("Sua vez, janela certa.", "Fora do caminho.", "O seletor que o Mac não tem."), mas não contêm o que as pessoas buscam. O site diz "seletor de janelas"; em português as pessoas buscam "alt tab no Mac", "alternar entre janelas", "trocar de janela", e a própria Apple usa "alternador de aplicativos". Nenhuma página responde a uma pergunta direta.

### Fora do site

- **O Tern não aparece nas buscas.** Uma busca por Tern + window switcher não encontra nada.
- **Colisão de nome.** "Tern" também é um terminal para Mac da Stencil ([stencil.so/tern](https://stencil.so/tern)), então buscar só pela marca leva ao outro produto.
- **GitHub fraco.** O repositório não tem topics, a descrição é "native macOS window switcher with exclusions" e há 1 estrela. Isso pesa: na busca "AltTab alternative", 4 dos 5 primeiros resultados foram READMEs de concorrentes pequenos no GitHub (Switch, BetterCmdTab, tab-switch, Reef).
- **O AltTab domina a categoria, inclusive em português.** Ele tem um guia [Como fazer alt-tab no Mac](https://alt-tab.app/pt-br/how-to-alt-tab-on-mac) e um [comparativo de alternadores](https://alt-tab.app/pt-br/mac-window-switchers), exatamente o tipo de página que as IAs citam.

### Onde o Tern pode ganhar

- **Busca grátis.** No AltTab, a busca por digitação é paga (Pro); no Tern é grátis.
- **Exclusões como centro do produto.** Esconder um app ou uma janela, regras por título, soneca, modos ligados ao Foco do macOS, Atalhos e `tern://`. Nenhum concorrente é construído em torno disso.
- **Um nicho ainda livre.** Buscas como "esconder app do alt tab" e "hide app from app switcher mac" são um espaço que o Tern pode ocupar.
- **Português nativo.** O app e o site já existem em pt-BR, um mercado com menos concorrência.

## Como as IAs escolhem o que recomendar

Pesquisas de 2026 que guiam as prioridades:

- **Relevância direta é o que mais pesa.** Uma página que responde à pergunta exata é a mais citada. Preço explícito e data recente também ajudam; mexer só na formatação quase não muda nada. Fonte: [What Gets Cited: Competitive GEO in AI Answer Engines](https://dl.acm.org/doi/pdf/10.1145/3805712.3808445), um estudo da ACM com 252 mil testes.
- **Cada IA busca em lugares diferentes.** Fonte: [B2B AI Citation Benchmark 2026](https://gadex.ai/resources/b2b-ai-citation-benchmark-2026/).
  - O ChatGPT cita principalmente páginas do próprio fabricante: produto, documentação, guias.
  - No Perplexity, 78% das citações vêm de comparativos, listas e reviews; Reddit e YouTube pesam bastante.
  - O Google AI Overviews acompanha de perto o ranking orgânico, além de listas e YouTube.
- **Menções à marca valem mais que backlinks.** Menções em outros sites se correlacionam com citações em IAs mais do que links apontando para o site.
- **`llms.txt` não tem efeito comprovado.** 97% dos arquivos nunca são lidos ([Ahrefs](https://ahrefs.com/blog/llmstxt-study/)). Fica no plano como item barato e de baixa prioridade.

Conclusão: o site precisa responder às perguntas com fatos, e o Tern precisa aparecer nas listas, comparativos e comunidades de onde as IAs tiram recomendações.

## Palavras-chave alvo

Não há dados de volume de busca ainda. Os grupos abaixo vêm das buscas que os concorrentes disputam e devem ser validados no Search Console de 4 a 6 semanas depois da Fase 1.

| Grupo | Português | Inglês |
|---|---|---|
| Categoria | alt tab no Mac, alternador de janelas Mac, app para trocar de janela no Mac | alt tab for Mac, window switcher for Mac, cmd tab show all windows |
| Como fazer | como fazer alt tab no Mac, como alternar entre janelas no Mac | how to alt tab on Mac, switch between windows Mac keyboard |
| Alternativas | alternativa ao AltTab, AltTab grátis com busca | AltTab alternative, free AltTab Pro alternative, Contexts alternative, Witch alternative |
| Diferencial | esconder app do alt tab Mac, esconder janela do alternador | hide app from app switcher Mac, exclude app from alt-tab, hide Picture in Picture from window switcher |

## Fase 1: base técnica (1 a 2 dias)

- [ ] **`site/vercel.json`** (o Vercel serve `site/` como raiz). Ativar `trailingSlash: true`, para `/en` redirecionar a `/en/`, e redirecionar com 301 `/index.html` e `/en/index.html` para as versões com barra.
- [ ] **Remover o redirecionamento automático por idioma** das páginas em português. No lugar, um aviso discreto ("Also available in English") para quem tem o navegador em outro idioma. A escolha salva em `localStorage` continua valendo.
- [ ] **`canonical` e `hreflang` com URLs absolutas** (`https://tern.gitlher.me/...`) nas quatro páginas atuais e em todas as futuras.
- [ ] **`site/robots.txt`** liberando tudo, inclusive GPTBot, OAI-SearchBot, ClaudeBot, Claude-SearchBot, PerplexityBot e Google-Extended, com a linha `Sitemap:`.
- [ ] **`site/sitemap.xml`** com cada página, as alternâncias de idioma (`xhtml:link`) e `lastmod`.
- [ ] **Open Graph e Twitter Card** (`og:title`, `og:description`, `og:image`, `og:locale`, `twitter:card`), com uma imagem PNG 1200×630 por idioma feita a partir de `brand/`.
- [ ] **JSON-LD `SoftwareApplication`** nas duas homes, com:
  - `name` e `alternateName` ("Tern window switcher", "Tern for Mac"), para separar do Tern da Stencil;
  - `applicationCategory` `UtilitiesApplication` e `operatingSystem` "macOS 13 or later";
  - `offers` com preço 0;
  - `softwareVersion`, `dateModified` e `downloadUrl`;
  - `license` MIT;
  - `author` (Guilherme Vieira, gitlher.me);
  - `sameAs` (repositório no GitHub e, depois, AlternativeTo, Product Hunt e YouTube);
  - `screenshot`.
- [ ] **Imagem real do app na página.** Um screenshot ou o vídeo de `brand/demo/` com `poster` e texto alternativo descritivo, além da animação em HTML.
- [ ] **Release mantém o site fresco.** Em `scripts/release.sh` e na seção de releases do `AGENTS.md`: a cada versão, atualizar `softwareVersion` e `dateModified` no JSON-LD e o `lastmod` do sitemap.
- [ ] **Regras no `AGENTS.md`** para páginas novas: `canonical` e `hreflang` absolutos, entrada no sitemap, versão nos dois idiomas.
- [ ] Baixa prioridade: hospedar a fonte Manrope no próprio site (desempenho e privacidade) e publicar um `llms.txt` simples.

## Fase 2: conteúdo no site (1 a 2 semanas)

Regras para todas as páginas novas:

- Saem em português e inglês, ligadas por `hreflang`, no sitemap, com "Atualizado em …" visível e link no menu ou no rodapé.
- Respondem na primeira frase e trazem só fatos verificáveis.
- Usam as palavras-chave sem repetição forçada e mantêm o tom do site.
- Usam "alternador de janelas" em títulos, H1 e descrições. No corpo do texto, decidir entre manter "seletor" (igual ao app) ou trocar nos dois lugares.

### 1. Home reescrita para busca

- **Título.** "Tern — Alt+Tab no Mac: alternador de janelas grátis" / "Tern — Alt-Tab for Mac: free, open-source window switcher".
- **Descrição.** Cita ⌥⇥, busca por digitação, esconder apps, grátis, código aberto e macOS 13+.
- **H1.** "Alt+Tab no Mac, janela por janela." / "Alt-Tab for Mac, one window at a time." Logo abaixo, em destaque menor, o slogan "Sua vez, janela certa." / "Your turn, right window.".
- **Bloco de fatos.** Grátis, licença MIT, macOS 13 ou posterior, Apple silicon e Intel, versão e data da última atualização, sem conta e sem rastreamento.
- **Perguntas frequentes.** De 6 a 8 perguntas, cada resposta em 2 ou 3 frases que se sustentam sozinhas, com JSON-LD `FAQPage`. O Google já não mostra esse resultado especial para a maioria dos sites, mas a marcação continua legível para as IAs. Exemplos:
  - O Mac tem Alt+Tab?
  - Qual a diferença entre o Tern e o ⌘⇥?
  - O Tern é grátis?
  - Por que o Tern pede Acessibilidade?
  - Por que o macOS avisa na primeira abertura? Explicar o certificado próprio e o código aberto, e como abrir.
  - Dá para esconder um app do alternador?
  - Qual a diferença entre o Tern e o AltTab?

### 2. Guia "Como fazer Alt+Tab no Mac"

`/alt-tab-no-mac/` e `/en/alt-tab-on-mac/`.

- O que o macOS já oferece: ⌘⇥, ⌘ + acento grave e Mission Control.
- Onde isso falha: alterna apps, não janelas.
- Como fazer com o Tern, passo a passo.

É a busca de topo da categoria.

### 3. Comparativo honesto

`/alternativas-ao-alttab/` e `/en/alttab-alternatives/`.

- **O que compara.** Tern, AltTab (grátis e Pro), Contexts, Witch, Raycast e as opções nativas.
- **Método.** Data, critérios e preço de cada um.
- **Onde o Tern perde.** Não é notarizado, e há limitações a confirmar no código, como janelas em outros Spaces.
- **Checagem.** Cada afirmação sobre concorrentes precisa ser conferida no site deles antes de publicar.

É o formato que o Perplexity mais cita, e só funciona se for justo.

### 4. Página do diferencial

`/esconder-apps-do-alternador/` e `/en/hide-apps-from-window-switcher/`.

- O ⌘⇥ do sistema não deixa esconder apps.
- No Tern dá para esconder o app inteiro, uma janela só ou janelas por regra de título (Picture in Picture), além de soneca e modos ligados ao Foco do macOS.

### 5. Ajuda

`/ajuda/` e `/en/help/`.

- **Instalação passo a passo**, com capturas de tela do "Abrir Mesmo Assim". Sem notarização, quem chega por uma busca precisa passar por essa tela sem desistir.
- **Permissões:** Acessibilidade, Gravação da Tela e Monitoramento de Entrada.
- **Solução de problemas:** o atalho não abre, o ⌥⇥ dispara também no app da frente, a Acessibilidade depois de atualizar.
- **Automação:** app Atalhos e links `tern://`.

Documentação é o tipo de página que o ChatGPT mais cita, e de quebra reduz suporte.

## Fase 3: GitHub e presença fora do site (começa junto e é contínua)

### GitHub (30 minutos, alto impacto)

- [ ] **Descrição.** "Free, open-source Alt-Tab for Mac: a window switcher that lets you hide the apps you don't need."
- [ ] **Topics.** `macos`, `alt-tab`, `alttab`, `window-switcher`, `app-switcher`, `task-switcher`, `cmd-tab`, `menubar-app`, `swift`, `swiftui`, `productivity`, `alttab-alternative`.
- [ ] **Imagem de prévia social**, a mesma do Open Graph.
- [ ] **README.md e README.pt-BR.md.** Primeiro parágrafo com os termos da categoria, uma seção curta "Tern vs AltTab" e um FAQ.

### Listas e diretórios

Um PR ou formulário para cada um. Antes de enviar, conferir as regras: alguns recusam apps não notarizados ou exigem um mínimo de estrelas.

- [ ] [open-source-mac-os-apps](https://github.com/serhii-londar/open-source-mac-os-apps): a que mais combina, por ser só de apps de código aberto.
- [ ] [awesome-mac](https://github.com/jaywcjlove/awesome-mac), na seção de gerenciamento de janelas.
- [ ] [awesome-macOS](https://github.com/iCHAIT/awesome-macOS).
- [ ] AlternativeTo: cadastrar o Tern como alternativa a AltTab, Contexts, Witch e HyperSwitch. É muito citado em perguntas do tipo "alternativa ao X".
- [ ] Pedir inclusão em comparativos que já existem: o do Manico e o comparativo do próprio AltTab, que lista outros alternadores.

### Comunidades

Um lançamento coordenado, uma vez por canal, sem spam.

- [ ] Show HN, r/macapps e Product Hunt.
- [ ] Brasil: TabNews, r/brdev e sugestão de pauta para MacMagazine, Tecnoblog e Canaltech.
- [ ] Responder a perguntas que já existem ("alt tab no Mac?") no Reddit, no Apple Communities e no Ask Different, sempre dizendo que é o autor.

### YouTube

- [ ] Publicar os vídeos de `brand/demo/` em português e inglês, com títulos de busca, por exemplo "Alt+Tab no Mac: troque de janela com o Tern (grátis)", e incorporá-los no site. O Google AI Overviews e o Perplexity citam YouTube.

### Homebrew

Desde 1º de setembro de 2026, o repositório oficial do Homebrew só aceita apps notarizados. Sem notarização, a opção é um tap próprio (`gitlherme/homebrew-tern`), que ajuda a divulgar entre devs mas não tira o aviso do Gatekeeper. Prioridade baixa.

## Medição

- [ ] **Google Search Console e Bing Webmaster Tools**, com o sitemap enviado. O Bing alimenta o ChatGPT e o Copilot. Depois da Fase 1, usar a inspeção de URL em `/` para confirmar que o Google indexa a home em português.
- [ ] **Downloads e origem do tráfego.** Downloads por release pela API do GitHub e "Referring sites" em Insights › Traffic.
- [ ] **Painel mensal de IAs.** Uns 12 prompts fixos, em português e inglês, no ChatGPT, Perplexity, Gemini, Google AI Mode e Claude, anotando se o Tern aparece e qual URL é citada. Exemplos:
  - qual o melhor app de Alt+Tab para Mac?
  - alternativa grátis ao AltTab com busca
  - como esconder um app do alternador de janelas no Mac
  - best free open-source window switcher for macOS
  - AltTab alternative that can hide apps
- [ ] **Logs do Vercel.** Confirmar que GPTBot, OAI-SearchBot, PerplexityBot e ClaudeBot recebem 200.
- [ ] **Opcional:** Vercel Web Analytics, que não usa cookies, se quiser números de visita sem contrariar o "sem rastreamento".

## Ordem e expectativa

| Quando | O quê |
|---|---|
| Semana 1 | Fase 1, GitHub, Search Console e Bing |
| Semanas 2–3 | Home, FAQ, guia de Alt+Tab e ajuda |
| Semanas 3–4 | Comparativo, página do diferencial e vídeos |
| Depois | Lançamento nas comunidades, listas e AlternativeTo; painel de IAs todo mês |

O que esperar:

- As correções técnicas e a indexação aparecem em 1 a 4 semanas.
- Buscas de cauda longa e em português tendem a responder mais rápido.
- "Alt tab Mac" contra o AltTab leva meses e depende principalmente das menções externas.
- IAs com busca na web (ChatGPT, Perplexity) passam a citar semanas depois de o Tern estar indexado e mencionado. O que os modelos "sabem de memória" só muda nas próximas versões deles.

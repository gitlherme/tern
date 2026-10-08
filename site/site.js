// Chave Pix da página em português. Troque só aqui.
const PIX_KEY = "pix@gitlher.me";

(() => {
  const KEY = "tern-lang";
  document.querySelectorAll("[data-lang]").forEach((a) => {
    a.addEventListener("click", () => {
      try { localStorage.setItem(KEY, a.dataset.lang); } catch (e) {}
    });
  });

  let saved = null;
  try { saved = localStorage.getItem(KEY); } catch (e) {}

  const isPT = document.documentElement.lang.toLowerCase().startsWith("pt");
  const enURL = document.body.dataset.en;
  const ptURL = document.body.dataset.pt;

  if (saved === "en" && isPT && enURL) {
    location.replace(enURL);
    return;
  }
  if (saved === "pt" && !isPT && ptURL) {
    location.replace(ptURL);
    return;
  }
  if (saved) return;

  const browserPT = /^(pt)/i.test(navigator.language || "");
  if (isPT && !browserPT && enURL) {
    showBanner({
      html: 'Also available in English. <a href="' + enURL + '" hreflang="en" lang="en" data-lang="en">English</a>',
      stay: "Stay in Portuguese",
      stayLang: "pt"
    });
  } else if (!isPT && browserPT && ptURL) {
    showBanner({
      html: 'Também em português. <a href="' + ptURL + '" hreflang="pt-BR" lang="pt-BR" data-lang="pt">Português</a>',
      stay: "Stay in English",
      stayLang: "en"
    });
  }

  function showBanner({ html, stay, stayLang }) {
    const bar = document.createElement("div");
    bar.className = "lang-banner on";
    bar.innerHTML = '<div class="wrap"><p>' + html + '</p><button type="button">' + stay + "</button></div>";
    const link = bar.querySelector("[data-lang]");
    if (link) {
      link.addEventListener("click", () => {
        try { localStorage.setItem(KEY, link.dataset.lang); } catch (e) {}
      });
    }
    bar.querySelector("button").addEventListener("click", () => {
      try { localStorage.setItem(KEY, stayLang); } catch (e) {}
      bar.remove();
    });
    document.body.insertBefore(bar, document.body.firstChild);
  }
})();

function copyText(text) {
  if (navigator.clipboard && typeof navigator.clipboard.writeText === "function" && window.isSecureContext) {
    return navigator.clipboard.writeText(text).then(() => true, () => legacyCopy(text));
  }
  return Promise.resolve(legacyCopy(text));
}

function legacyCopy(text) {
  const previouslyFocused = document.activeElement;
  const area = document.createElement("textarea");
  area.value = text;
  area.setAttribute("aria-hidden", "true");
  area.style.cssText = "position:fixed;top:0;left:0;width:2em;height:2em;padding:0;border:none;outline:none;box-shadow:none;background:transparent;font-size:16px;";
  document.body.appendChild(area);

  const selection = document.getSelection();
  const previous = selection && selection.rangeCount ? selection.getRangeAt(0) : null;
  area.focus();
  area.select();
  try { area.setSelectionRange(0, text.length); } catch (e) {}

  let ok = false;
  try { ok = document.execCommand("copy"); } catch (e) { ok = false; }

  area.remove();
  if (selection) {
    selection.removeAllRanges();
    if (previous) selection.addRange(previous);
  }
  if (previouslyFocused && previouslyFocused.focus) previouslyFocused.focus();
  return ok;
}

(() => {
  const slot = document.querySelector("[data-pix-key]");
  if (slot) slot.textContent = PIX_KEY;

  const button = document.querySelector("[data-copy-pix]");
  if (!button) return;

  const idle = button.textContent.trim();
  const done = button.getAttribute("data-copied-label") || "Copiado ✓";
  let timer = 0;

  button.addEventListener("click", () => {
    copyText(PIX_KEY).then((ok) => {
      if (!ok) {
        button.textContent = idle;
        return;
      }
      button.textContent = done;
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        button.textContent = idle;
      }, 2000);
    });
  });
})();

window.ternDemo = function (opts) {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const cards = [...document.querySelectorAll("#cards .card")];
  if (!cards.length) return;
  const hud = document.getElementById("hud");
  const q = document.getElementById("q");
  const count = document.getElementById("count");
  const caption = document.getElementById("caption");
  const word = opts.word;
  let i = 1;
  let phase = "browse";
  let ticks = 0;
  setInterval(() => {
    if (phase === "browse") {
      hud.classList.remove("searching");
      cards.forEach((c) => c.classList.remove("dim"));
      cards[i].classList.remove("on");
      i = (i + 1) % cards.length;
      cards[i].classList.add("on");
      count.textContent = opts.countAll;
      caption.innerHTML = opts.browseCaption;
      if (++ticks >= 3) { phase = "type"; ticks = 0; q.textContent = ""; }
    } else if (phase === "type") {
      hud.classList.add("searching");
      q.textContent = word.slice(0, ticks + 1);
      if (++ticks >= word.length) {
        cards.forEach((c) => {
          const hit = c.hasAttribute("data-hit");
          c.classList.toggle("dim", !hit);
          c.classList.toggle("on", hit);
        });
        count.textContent = opts.countOne;
        caption.innerHTML = opts.searchCaption;
        phase = "hold";
        ticks = 0;
      }
    } else if (++ticks >= 3) {
      phase = "browse";
      ticks = 0;
    }
  }, 900);
};

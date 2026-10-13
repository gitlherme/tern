// Lenis 1.3.26 + GSAP 3.15.0. Só enriquece; o conteúdo já está visível sem isto.
(function () {
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduce || !window.Lenis || !window.gsap) {
    document.documentElement.classList.remove("js");
    return;
  }

  const { gsap } = window;
  if (window.ScrollTrigger) gsap.registerPlugin(window.ScrollTrigger);
  if (window.MotionPathPlugin) gsap.registerPlugin(window.MotionPathPlugin);

  const easeOut = "cubic-bezier(0.16, 1, 0.3, 1)";
  const easeGlide = "cubic-bezier(0.45, 0, 0.25, 1)";
  const fine = matchMedia("(pointer: fine)").matches;
  const mobile = matchMedia("(max-width: 759px)").matches;
  const wide = matchMedia("(min-width: 1024px)").matches;

  const lenis = new Lenis({ lerp: 0.1, smoothWheel: true });
  lenis.on("scroll", () => {
    if (window.ScrollTrigger) ScrollTrigger.update();
  });
  gsap.ticker.add((t) => lenis.raf(t * 1000));
  gsap.ticker.lagSmoothing(0);

  document.querySelectorAll('a[href^="#"]').forEach((a) => {
    a.addEventListener("click", (e) => {
      const id = a.getAttribute("href");
      if (!id || id.length < 2) return;
      const target = document.querySelector(id);
      if (!target) return;
      e.preventDefault();
      lenis.scrollTo(id, { offset: -24 });
      history.replaceState(null, "", id);
    });
  });

  const pauseOffscreen = (el, looping) => {
    if (!el || !("IntersectionObserver" in window)) return;
    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        el.classList.toggle("is-off", !entry.isIntersecting);
        if (looping) {
          if (entry.isIntersecting) looping.play();
          else looping.pause();
        }
      });
    }, { threshold: 0.05 });
    io.observe(el);
  };

  const heroH1 = document.querySelector(".hero-h1");
  if (heroH1) {
    gsap.to(".hero-h1 .word", {
      y: 0,
      opacity: 1,
      stagger: 0.06,
      duration: 0.64,
      ease: easeOut,
    });
    const sticker = heroH1.querySelector(".sticker");
    if (sticker) {
      gsap.to(sticker, {
        rotate: -2.5,
        scale: 1,
        duration: 0.64,
        ease: easeOut,
        delay: 0.36,
      });
    }
  }

  if (!mobile && fine) {
    document.querySelectorAll(".hero-key").forEach((el) => {
      const xTo = gsap.quickTo(el, "x", { duration: 0.6, ease: "power3.out" });
      const yTo = gsap.quickTo(el, "y", { duration: 0.6, ease: "power3.out" });
      window.addEventListener("pointermove", (ev) => {
        const r = el.getBoundingClientRect();
        const cx = r.left + r.width / 2;
        const cy = r.top + r.height / 2;
        const dx = ((ev.clientX - cx) / window.innerWidth) * 24;
        const dy = ((ev.clientY - cy) / window.innerHeight) * 24;
        xTo(Math.max(-12, Math.min(12, dx)));
        yTo(Math.max(-12, Math.min(12, dy)));
      });
    });
  }

  const hero = document.querySelector(".hero");
  if (hero) pauseOffscreen(hero);

  const mac = document.querySelector(".mac");
  const stage = document.querySelector(".stage-persp");
  if (mac && stage && window.ScrollTrigger) {
    gsap.to(mac, {
      rotateX: 0,
      scale: 1,
      ease: "none",
      scrollTrigger: {
        trigger: stage,
        start: "top bottom",
        end: "center center",
        scrub: true,
      },
    });
  }

  const marquee = document.querySelector(".marquee-track");
  const marqueeSec = document.querySelector(".marquee");
  if (marquee) {
    gsap.set(marquee, { animation: "none" });
    const tween = gsap.to(marquee, {
      xPercent: -50,
      duration: 38,
      ease: "none",
      repeat: -1,
    });
    lenis.on("scroll", () => {
      tween.timeScale(1 + Math.min(Math.abs(lenis.velocity) * 0.05, 3));
    });
    pauseOffscreen(marqueeSec, tween);
  }

  if (window.ScrollTrigger) {
    ScrollTrigger.batch(".tile", {
      start: "top 80%",
      once: true,
      onEnter: (batch) => {
        gsap.to(batch, {
          y: 0,
          opacity: 1,
          stagger: 0.06,
          duration: 0.64,
          ease: easeOut,
        });
      },
    });
  }

  const hideSec = document.querySelector(".hide-pin");
  const hideTrack = document.querySelector(".hide-track");
  if (hideSec && hideTrack && wide && window.ScrollTrigger && !mobile) {
    const gutter = parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--gutter")) || 32;
    const distance = () => Math.max(0, hideTrack.scrollWidth - window.innerWidth + gutter);
    gsap.to(hideTrack, {
      x: () => -distance(),
      ease: "none",
      scrollTrigger: {
        trigger: hideSec,
        pin: true,
        scrub: true,
        anticipatePin: 1,
        end: () => "+=" + distance(),
      },
    });
  }

  if (window.ScrollTrigger) {
    document.querySelectorAll(".keylist li").forEach((li) => {
      ScrollTrigger.create({
        trigger: li,
        start: "top center",
        end: "bottom center",
        onEnter: () => {
          li.classList.add("is-pressed");
          setTimeout(() => li.classList.remove("is-pressed"), 300);
        },
        onEnterBack: () => {
          li.classList.add("is-pressed");
          setTimeout(() => li.classList.remove("is-pressed"), 300);
        },
      });
    });

    const ternCells = document.querySelectorAll("table.compare .cmp-tern");
    if (ternCells.length) {
      ScrollTrigger.create({
        trigger: "table.compare",
        start: "top 70%",
        once: true,
        onEnter: () => {
          gsap.to(ternCells, {
            clipPath: "inset(0)",
            duration: 0.64,
            ease: easeOut,
          });
        },
      });
    }
  }

  const ctaBird = document.querySelector(".cta-bird");
  const finalCta = document.querySelector(".final-cta");
  if (ctaBird && finalCta && window.ScrollTrigger) {
    if (window.MotionPathPlugin) {
      gsap.fromTo(
        ctaBird,
        { opacity: 1, x: 180, y: -140, rotate: -18 },
        {
          duration: 1.2,
          ease: easeGlide,
          motionPath: {
            path: [
              { x: 180, y: -140 },
              { x: 40, y: -40 },
              { x: 0, y: 0 },
            ],
            curviness: 1.2,
            autoRotate: false,
          },
          scrollTrigger: {
            trigger: finalCta,
            start: "top 60%",
            once: true,
          },
        }
      );
    } else {
      gsap.fromTo(
        ctaBird,
        { opacity: 0, x: 80, y: -60 },
        {
          opacity: 1, x: 0, y: 0,
          duration: 1.2,
          ease: easeGlide,
          scrollTrigger: { trigger: finalCta, start: "top 60%", once: true },
        }
      );
    }
  }

  const pageFade = document.querySelector(".page-fade");
  if (pageFade) {
    gsap.to(pageFade, { opacity: 1, duration: 0.64, ease: easeOut });
  }

  const ready = document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve();
  ready.then(() => {
    if (window.ScrollTrigger) ScrollTrigger.refresh();
  });
})();

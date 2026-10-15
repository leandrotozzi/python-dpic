/* tutorial/assets/guide.js — page chrome shared by index, guides and the Verilator gaps page.
   Injects: top bar (logo, step map, quiz score, theme), reading progress, hero number, code-block headers with copy,
   TOC checklist (active + seen, remembered per page), prev/next pager. Also renders KaTeX if it is loaded.
   Load with <script defer src="../assets/guide.js"></script> after the KaTeX scripts. */
var STEPS = [
  ["01_first_call", "First call"], ["02_data_types", "Data types"], ["03_state_and_handles", "State and handles"],
  ["04_arrays_structs_strings", "Arrays, structs, strings"], ["05_export_and_context", "Export and context"],
  ["06_golden_model_c", "Golden model in C"], ["07_embedding_python", "Embedding Python"], ["08_python_golden_model", "Python golden model"]
];
var THEME_KEY = "dpic-theme";
var REPO = "https://github.com/leandrotozzi/python-dpic";

function theme() {
  var r = document.documentElement, n = r.dataset.theme === "light" ? "dark" : "light";
  r.dataset.theme = n;
  try { localStorage.setItem(THEME_KEY, n); } catch (e) {}
}
function setAll(open) { document.querySelectorAll("main details").forEach(function (d) { d.open = open; }); }
function store(k, v) { try { if (v === undefined) return JSON.parse(localStorage.getItem(k) || "null"); localStorage.setItem(k, JSON.stringify(v)); } catch (e) { return null; } }

document.addEventListener("DOMContentLoaded", function () {
  var parts = location.pathname.split("/"), folder = parts[parts.length - 2] || "";
  var cur = STEPS.findIndex(function (s) { return s[0] === folder; });
  var base = cur >= 0 ? "../" : "";
  var page = parts[parts.length - 1] || "index.html";
  var main = document.querySelector("main");

  if (window.renderMathInElement) renderMathInElement(document.body, { delimiters: [{ left: "$$", right: "$$", display: true }, { left: "$", right: "$", display: false }], throwOnError: false });

  /* top bar */
  var bar = document.createElement("header");
  bar.className = "gbar";
  var map = STEPS.map(function (s, i) {
    return (i ? (i === 6 ? '<span class="sep"></span>' : "<i></i>") : "") +
      '<a href="' + base + s[0] + '/guide.html" title="' + String(i + 1).padStart(2, "0") + " · " + s[1] + '"' + (i === cur ? ' class="cur"' : "") + ">" + String(i + 1).padStart(2, "0") + "</a>";
  }).join("");
  map += '<a class="gaps' + (page === "verilator_gaps.html" ? " cur" : "") + '" href="' + base + 'verilator_gaps.html" title="What doesn\'t work in Verilator">!</a>';
  var nq = document.querySelectorAll(".quiz").length;
  bar.innerHTML = '<a class="logo" href="' + base + 'index.html" title="Tutorial index">DPI-C</a><nav class="map">' + map + "</nav>" +
    (nq ? '<span class="score" id="gscore">0 / ' + nq + " quiz</span>" : "") +
    '<a class="gh" href="' + REPO + '" title="Source on GitHub">GitHub</a>' +
    '<button type="button" onclick="theme()" aria-label="Toggle light/dark theme">◐</button><div class="prog" id="gprog"></div>';
  document.body.insertBefore(bar, document.body.firstChild);

  /* on GitHub Pages, links to source files (.sv, .c, .py, .md, folders) open on GitHub instead of downloading */
  if (/\.github\.io$/.test(location.hostname)) {
    var root = new URL(base || "./", location.href).pathname;
    document.querySelectorAll("a[href]").forEach(function (a) {
      var h = a.getAttribute("href");
      if (/^[a-z]+:|^#|\.html(#|$)/i.test(h)) return;
      var p = new URL(h, location.href).pathname;
      if (p.indexOf(root) !== 0) return;
      p = p.slice(root.length).replace(/\/$/, "");
      a.href = REPO + (/\.[a-z0-9]+$/i.test(p) ? "/blob/" : "/tree/") + "master/tutorial/" + p;
    });
  }
  var prog = document.getElementById("gprog");
  addEventListener("scroll", function () {
    var h = document.documentElement, f = h.scrollTop / Math.max(1, h.scrollHeight - h.clientHeight);
    prog.style.width = (100 * f) + "%";
  }, { passive: true });

  /* quiz score in the bar (quiz.js marks .ok / .bad) */
  if (nq) new MutationObserver(function () {
    var ok = document.querySelectorAll(".quiz.ok").length, done = document.querySelectorAll(".quiz.ok,.quiz.bad").length;
    document.getElementById("gscore").textContent = ok + " / " + nq + " quiz" + (done > ok ? " · " + (done - ok) + " wrong" : "");
  }).observe(main || document.body, { subtree: true, attributes: true, attributeFilter: ["class"] });

  /* hero: kicker + h1 + deck + meta, plus the big step number */
  var h1 = main && main.querySelector("h1");
  if (h1 && !h1.closest(".hero")) {
    var hero = document.createElement("div"), txt = document.createElement("div");
    hero.className = "hero"; h1.parentNode.insertBefore(hero, h1);
    var prev = hero.previousElementSibling;
    if (prev && prev.classList.contains("kicker")) txt.appendChild(prev);
    txt.appendChild(h1);
    ["deck", "meta"].forEach(function (c) { var n = hero.nextElementSibling; if (n && n.classList.contains(c)) txt.appendChild(n); });
    hero.appendChild(txt);
    if (cur >= 0) { var big = document.createElement("div"); big.className = "big"; big.textContent = String(cur + 1).padStart(2, "0"); hero.appendChild(big); hero.classList.add("has-big"); }
  }

  /* code blocks: header with language and copy button */
  var LANG = { sv: ["SystemVerilog", "sv"], cc: ["C", "c"], c: ["C", "c"], py: ["Python", "py"], sh: ["shell", "sh"], out: ["output", ""] };
  document.querySelectorAll("main pre").forEach(function (pre) {
    if (pre.parentNode.classList.contains("codeblk")) return;
    var cls = (pre.className.split(/\s+/).filter(function (c) { return LANG[c]; })[0]) || "", L = LANG[cls] || ["text", ""];
    var wrap = document.createElement("div"); wrap.className = "codeblk";
    wrap.innerHTML = '<header><span class="dot ' + L[1] + '"></span>' + L[0] + '<button type="button">copy</button></header>';
    pre.parentNode.insertBefore(wrap, pre); wrap.appendChild(pre);
    var btn = wrap.querySelector("button");
    btn.onclick = function () {
      navigator.clipboard.writeText(pre.innerText).then(function () { btn.textContent = "copied ✓"; setTimeout(function () { btn.textContent = "copy"; }, 1200); });
    };
  });

  /* syntax highlighting: highlight.js (vendored in assets/hljs), loaded on demand */
  var HL = { sv: "verilog", cc: "cpp", c: "cpp", py: "python", sh: "bash" };
  var pres = [].slice.call(document.querySelectorAll("main pre")).filter(function (p) { return p.className.split(/\s+/).some(function (c) { return HL[c]; }); });
  function load(src, cb) { var s = document.createElement("script"); s.src = base + "assets/hljs/" + src; s.onload = cb; s.onerror = function () {}; document.head.appendChild(s); }
  if (pres.length) load("highlight.min.js", function () {
    load("verilog.min.js", function () {
      pres.forEach(function (pre) {
        var lang = HL[pre.className.split(/\s+/).filter(function (c) { return HL[c]; })[0]];
        try { pre.innerHTML = hljs.highlight(pre.textContent, { language: lang, ignoreIllegals: true }).value; pre.classList.add("hljs"); } catch (e) {}
      });
    });
  });

  /* TOC: active section + checklist of sections already read (remembered per page) */
  var toc = document.getElementById("toc");
  if (toc) {
    if (matchMedia("(min-width:1100px)").matches) toc.open = true;
    var links = [].slice.call(toc.querySelectorAll('a[href^="#"]')), key = "dpic-seen:" + folder + "/" + page;
    var seen = store(key) || {};
    store("dpic-total:" + folder + "/" + page, links.length);
    var nav = toc.querySelector("nav") || toc, pb = document.createElement("div");
    pb.className = "tocprog"; pb.innerHTML = "<b></b>"; nav.insertBefore(pb, nav.firstChild);
    function paint() {
      var n = 0; links.forEach(function (a) { var s = !!seen[a.getAttribute("href")]; a.classList.toggle("seen", s); n += s; });
      pb.firstChild.style.width = (100 * n / Math.max(1, links.length)) + "%";
    }
    paint();
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (!e.isIntersecting) return;
        var id = "#" + e.target.id;
        links.forEach(function (a) { a.classList.toggle("on", a.getAttribute("href") === id); });
        if (!seen[id]) { seen[id] = 1; store(key, seen); paint(); }
      });
    }, { rootMargin: "0px 0px -70% 0px" });
    links.forEach(function (a) { var el = document.getElementById(a.getAttribute("href").slice(1)); if (el) io.observe(el); });
  }

  /* prev / next pager */
  if (cur >= 0 && main) {
    var p = STEPS[cur - 1], n = STEPS[cur + 1], pg = document.createElement("nav");
    pg.className = "pager";
    pg.innerHTML = (p ? '<a href="../' + p[0] + '/guide.html"><small>← previous</small>' + String(cur).padStart(2, "0") + " · " + p[1] + "</a>" : '<a href="../index.html"><small>← back</small>Tutorial index</a>') +
      (n ? '<a class="next" href="../' + n[0] + '/guide.html"><small>next →</small>' + String(cur + 2).padStart(2, "0") + " · " + n[1] + "</a>" : '<a class="next" href="../verilator_gaps.html"><small>next →</small>What doesn\'t work in Verilator</a>');
    var foot = main.querySelector(".foot");
    if (foot) main.insertBefore(pg, foot); else main.appendChild(pg);
  }
});

document.addEventListener("DOMContentLoaded", () => {
  const brand = document.querySelector(".navbar-brand");

  if (!brand || brand.textContent.trim() !== "gifter") {
    return;
  }

  const wordmark = document.createElement("span");
  wordmark.className = "gifter-wordmark";
  wordmark.append("gift");

  const suffix = document.createElement("span");
  suffix.className = "gifter-wordmark-suffix";
  suffix.textContent = "er";
  wordmark.append(suffix);

  brand.replaceChildren(wordmark);
});

// Breadcrumbs: gifter > section > page, read from the navbar so they follow
// _pkgdown.yml. A page the navbar does not list is placed under the API when it
// is a reference topic, and directly under gifter otherwise.
document.addEventListener("DOMContentLoaded", () => {
  const main = document.querySelector("main#main");
  const brand = document.querySelector(".navbar-brand");
  if (!main || !brand || document.body.querySelector(".template-home")) {
    return;
  }

  const here = (href) => {
    const url = new URL(href, window.location.href);
    return url.pathname.replace(/index\.html$/, "");
  };
  const current = here(window.location.href);
  const links = Array.from(document.querySelectorAll(".navbar a.nav-link, .navbar a.dropdown-item"))
    .filter((link) => here(link.href) === current);
  // A page linked several times (once per section of it) is named by the link
  // that opens it at the top.
  const match = links.find((link) => !new URL(link.href).hash) || links[0];

  const trail = [{ label: "gifter", href: brand.href }];
  if (match) {
    const menu = match.closest(".dropdown");
    if (menu) {
      trail.push({ label: menu.querySelector(".dropdown-toggle").textContent.trim() });
    }
    trail.push({ label: match.textContent.trim() });
  } else {
    if (document.querySelector(".template-reference-topic")) {
      const api = document.querySelector('.navbar a.nav-link[href$="reference/index.html"]');
      if (api) trail.push({ label: api.textContent.trim(), href: api.href });
    }
    const heading = main.querySelector("h1");
    trail.push({ label: heading ? heading.textContent.trim() : document.title });
  }

  const list = document.createElement("ol");
  trail.forEach((step, index) => {
    const item = document.createElement("li");
    const last = index === trail.length - 1;
    if (step.href && !last) {
      const link = document.createElement("a");
      link.href = step.href;
      link.textContent = step.label;
      item.append(link);
    } else {
      item.textContent = step.label;
      if (last) item.setAttribute("aria-current", "page");
    }
    list.append(item);
  });

  const nav = document.createElement("nav");
  nav.className = "gifter-breadcrumbs";
  nav.setAttribute("aria-label", "Breadcrumb");
  nav.append(list);
  main.prepend(nav);
});

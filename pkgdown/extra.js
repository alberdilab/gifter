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

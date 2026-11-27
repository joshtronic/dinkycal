// dinkycal.com: scale the hero animation to its frame, and copy the brew command.
(() => {
  const stage = document.querySelector(".stage");
  const scene = stage && stage.querySelector(".scene");
  if (scene) {
    const fit = () => scene.style.setProperty("--s", String(stage.clientWidth / scene.offsetWidth));
    new ResizeObserver(fit).observe(stage);
    fit();
  }

  document.querySelectorAll(".copy").forEach((btn) => {
    const tip = btn.querySelector(".tip");
    let timer;
    btn.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(btn.dataset.copy);
        btn.classList.add("done");
        tip.textContent = "Copied";
      } catch (_) {
        const range = document.createRange();
        range.selectNodeContents(document.getElementById("brew-cmd"));
        getSelection().removeAllRanges();
        getSelection().addRange(range);
        tip.textContent = "Press ⌘C";
      }
      tip.classList.add("show");
      clearTimeout(timer);
      timer = setTimeout(() => {
        btn.classList.remove("done");
        tip.classList.remove("show");
        tip.textContent = "";
      }, 1600);
    });
  });
})();

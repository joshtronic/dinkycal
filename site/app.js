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
    btn.addEventListener("click", async () => {
      const label = btn.querySelector("span");
      try {
        await navigator.clipboard.writeText(btn.dataset.copy);
        btn.classList.add("done");
        label.textContent = "Copied";
      } catch (_) {
        const range = document.createRange();
        range.selectNodeContents(document.getElementById("brew-cmd"));
        getSelection().removeAllRanges();
        getSelection().addRange(range);
        label.textContent = "Press ⌘C";
      }
      setTimeout(() => { btn.classList.remove("done"); label.textContent = "Copy"; }, 1800);
    });
  });
})();

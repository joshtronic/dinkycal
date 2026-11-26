// The live planner on dinkycal.com: the current month, a synthetic demo calendar,
// the same busy-hours rules as the app, hover distance, and peelable sticker dots.
(() => {
  const WINDOW_START = 9, WINDOW_END = 17; // the app's default busy window, 9 to 5

  // Demo events: [day of month, start hour, hours, title, allDay]
  const DEMO = [
    [2, 9.5, 0.5, "Standup"], [3, 10, 1, "1:1 with Sam"], [3, 13, 2, "Design review"],
    [5, 15, 1, "Dentist"], [9, 9.5, 0.5, "Standup"], [10, 9, 4, "Planning offsite"],
    [10, 14, 1.5, "Roadmap sync"], [12, 12, 1, "Lunch with Ana"], [16, 9.5, 0.5, "Standup"],
    [17, 10, 1, "1:1 with Sam"], [18, 0, 24, "Release day", true], [19, 11, 2.5, "Pairing"],
    [20, 16, 1, "Haircut"], [23, 9.5, 0.5, "Standup"], [24, 10, 1, "Interview loop"],
    [24, 13, 3, "Workshop"], [26, 9.5, 0.5, "Standup"], [26, 11, 1, "Design review"],
    [26, 14, 2, "Pairing with Lee"], [27, 18, 2, "Dinner with friends"], [30, 9, 6.5, "Conference talks"],
  ];

  const $ = (id) => document.getElementById(id);
  const monthEl = $("month");
  if (!monthEl) return;

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const year = today.getFullYear(), month = today.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const locale = navigator.language || "en-US";

  // Week start: follow the visitor's locale when the browser can tell us.
  let firstWeekday = 0;
  try {
    const info = new Intl.Locale(locale);
    const week = info.getWeekInfo ? info.getWeekInfo() : info.weekInfo;
    if (week && week.firstDay) firstWeekday = week.firstDay % 7;
  } catch (_) { /* Sunday */ }

  const events = {};
  for (const [day, hour, hours, title, allDay] of DEMO) {
    if (day > daysInMonth) continue;
    (events[day] ||= []).push({ hour, hours, title, allDay: !!allDay });
  }

  // Same rules as the app: clip to the window, merge overlaps, all-day = full.
  function busy(day) {
    const list = events[day] || [];
    if (!list.length) return { level: 0, text: "", count: 0 };
    if (list.some((e) => e.allDay)) return { level: 4, text: "All day", count: list.length };
    const spans = list
      .map((e) => [Math.max(e.hour, WINDOW_START), Math.min(e.hour + e.hours, WINDOW_END)])
      .filter(([a, b]) => a < b)
      .sort((x, y) => x[0] - y[0]);
    let total = 0, cur = null;
    for (const s of spans) {
      if (cur && s[0] <= cur[1]) cur[1] = Math.max(cur[1], s[1]);
      else { if (cur) total += cur[1] - cur[0]; cur = [...s]; }
    }
    if (cur) total += cur[1] - cur[0];
    const ratio = total / (WINDOW_END - WINDOW_START);
    const level = ratio < 0.25 ? 1 : ratio < 0.5 ? 2 : ratio < 0.75 ? 3 : 4;
    if (total > 0) {
      const half = Math.max(1, Math.round(total * 2));
      return { level, text: `${half % 2 ? (half / 2).toFixed(1) : half / 2}h busy`, count: list.length };
    }
    return { level: 1, text: list.length === 1 ? "1 event" : `${list.length} events`, count: list.length };
  }

  function distanceLabel(n) {
    if (n === 0) return "Today";
    if (n === 1) return "Tomorrow";
    if (n === -1) return "Yesterday";
    return n > 0 ? `In ${n} days` : `${-n} days ago`;
  }

  const dayMs = 86400000;
  const distance = (date) => Math.round((Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) -
    Date.UTC(year, month, today.getDate())) / dayMs);

  const fmtTime = (h) => new Date(2000, 0, 1, Math.floor(h), Math.round((h % 1) * 60))
    .toLocaleTimeString(locale, { hour: "numeric", minute: "2-digit" });

  // Header + weekday row.
  $("month-title").textContent = today.toLocaleDateString(locale, { month: "long", year: "numeric" });
  const weekdays = $("weekdays");
  for (let i = 0; i < 7; i++) {
    const d = new Date(2024, 0, 7 + ((firstWeekday + i) % 7)); // Jan 7 2024 is a Sunday
    const span = document.createElement("span");
    span.textContent = d.toLocaleDateString(locale, { weekday: "short" });
    weekdays.append(span);
  }

  // Grid: leading days from last month, this month, then trailing days to finish the week.
  const lead = (new Date(year, month, 1).getDay() - firstWeekday + 7) % 7;
  const cells = Math.ceil((lead + daysInMonth) / 7) * 7;
  const levels = {}; // per-day level, so stuck stickers persist
  const cellsByDay = {};
  let selected = today.getDate();

  for (let i = 0; i < cells; i++) {
    const date = new Date(year, month, 1 - lead + i);
    const inMonth = date.getMonth() === month;
    const n = date.getDate();
    const cell = document.createElement("button");
    cell.type = "button";
    cell.className = "day" + (inMonth ? "" : " out") + (inMonth && n === today.getDate() ? " today" : "");
    cell.tabIndex = inMonth && n === selected ? 0 : -1;
    cell.dataset.offset = String(i);
    cell.innerHTML = `<span class="num">${n}</span><span class="spot"></span>`;
    if (inMonth) {
      cellsByDay[n] = cell;
      cell.dataset.day = String(n);
      levels[n] = busy(n).level;
      paintDot(n, i);
    } else {
      cell.disabled = true;
      cell.setAttribute("aria-hidden", "true");
    }
    monthEl.append(cell);
  }

  function paintDot(day, index) {
    const spot = cellsByDay[day].querySelector(".spot");
    spot.innerHTML = "";
    const level = levels[day];
    if (level > 0) {
      const dot = document.createElement("span");
      dot.className = "dot stuck";
      dot.dataset.level = String(level);
      dot.style.setProperty("--i", String(index ?? 0));
      spot.append(dot);
    }
    const b = busy(day);
    const date = new Date(year, month, day);
    cellsByDay[day].setAttribute("aria-label",
      `${date.toLocaleDateString(locale, { weekday: "long", month: "long", day: "numeric" })}, ${distanceLabel(distance(date))}${b.text ? ", " + b.text : ""}`);
  }

  function show(day) {
    const date = new Date(year, month, day);
    const b = busy(day);
    const custom = levels[day] !== b.level;
    $("r-date").textContent = date.toLocaleDateString(locale, { weekday: "short", month: "short", day: "numeric" });
    $("r-dist").textContent = distanceLabel(distance(date));
    $("r-busy").textContent = custom ? "You stuck a dot here." : (b.text || "Nothing scheduled.");
    const list = $("r-events");
    list.innerHTML = "";
    const dayEvents = (events[day] || []).slice().sort((a, b2) => (b2.allDay - a.allDay) || a.hour - b2.hour);
    for (const e of dayEvents) {
      const li = document.createElement("li");
      li.innerHTML = `<span></span><span></span>`;
      li.children[0].textContent = e.allDay ? "All day" : `${fmtTime(e.hour)}`;
      li.children[1].textContent = e.title;
      list.append(li);
    }
    list.hidden = dayEvents.length === 0 || custom;
  }

  function select(day, focus) {
    if (cellsByDay[selected]) { cellsByDay[selected].classList.remove("selected"); cellsByDay[selected].tabIndex = -1; }
    selected = day;
    const cell = cellsByDay[day];
    cell.classList.add("selected");
    cell.tabIndex = 0;
    if (focus) cell.focus();
    show(day);
  }

  monthEl.addEventListener("pointerover", (e) => {
    const cell = e.target.closest(".day[data-day]");
    if (cell) show(+cell.dataset.day);
  });
  monthEl.addEventListener("pointerleave", () => show(selected));
  monthEl.addEventListener("focusin", (e) => {
    const cell = e.target.closest(".day[data-day]");
    if (cell) show(+cell.dataset.day);
  });
  monthEl.addEventListener("click", (e) => {
    const cell = e.target.closest(".day[data-day]");
    if (!cell) return;
    const day = +cell.dataset.day;
    if (armed) { stick(day, armed); disarm(); }
    select(day, false);
  });
  monthEl.addEventListener("keydown", (e) => {
    const step = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }[e.key];
    if (!step) return;
    const next = selected + step;
    if (cellsByDay[next]) { e.preventDefault(); select(next, true); }
  });

  function stick(day, level) {
    levels[day] = level;
    paintDot(day, 0);
    show(day);
  }

  // Peel a dot: drag it onto a day, or press it and then click a day.
  let armed = 0;
  const peels = document.querySelectorAll(".peel");
  function disarm() { armed = 0; peels.forEach((p) => p.setAttribute("aria-pressed", "false")); }

  peels.forEach((peel) => {
    peel.addEventListener("click", () => {
      const level = +peel.dataset.level;
      const on = armed !== level;
      disarm();
      if (on) { armed = level; peel.setAttribute("aria-pressed", "true"); }
    });

    peel.addEventListener("pointerdown", (e) => {
      if (e.button !== 0) return;
      const level = +peel.dataset.level;
      const startX = e.clientX, startY = e.clientY;
      let ghost = null, target = null;

      const move = (ev) => {
        if (!ghost && Math.hypot(ev.clientX - startX, ev.clientY - startY) < 6) return;
        if (!ghost) {
          ghost = document.createElement("span");
          ghost.className = "dot ghost";
          ghost.dataset.level = String(level);
          document.body.append(ghost);
        }
        ghost.style.left = ev.clientX + "px";
        ghost.style.top = ev.clientY + "px";
        const under = document.elementFromPoint(ev.clientX, ev.clientY);
        const cell = under && under.closest(".day[data-day]");
        if (cell !== target) {
          target?.classList.remove("drop-target");
          target = cell;
          target?.classList.add("drop-target");
          if (target) show(+target.dataset.day);
        }
      };
      const up = () => {
        window.removeEventListener("pointermove", move);
        window.removeEventListener("pointerup", up);
        if (ghost) {
          ghost.remove();
          if (target) { target.classList.remove("drop-target"); stick(+target.dataset.day, level); select(+target.dataset.day, false); }
          disarm();
          peel.addEventListener("click", (ce) => ce.stopImmediatePropagation(), { once: true, capture: true });
        }
      };
      window.addEventListener("pointermove", move);
      window.addEventListener("pointerup", up);
    });
  });

  // Copy the brew command.
  document.querySelectorAll(".copy").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const label = btn.querySelector("span");
      try {
        await navigator.clipboard.writeText(btn.dataset.copy);
        btn.classList.add("done");
        label.textContent = "Copied";
      } catch (_) {
        const range = document.createRange();
        range.selectNodeContents($("brew-cmd"));
        getSelection().removeAllRanges();
        getSelection().addRange(range);
        label.textContent = "Press ⌘C";
      }
      setTimeout(() => { btn.classList.remove("done"); label.textContent = "Copy"; }, 1800);
    });
  });

  select(today.getDate(), false);
})();

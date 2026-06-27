/* Shift Tracker — punch in/out + biweekly hours. All data stored locally. */
(() => {
  'use strict';

  const STORE_KEY = 'shiftTracker.shifts.v1';
  const SETTINGS_KEY = 'shiftTracker.settings.v1';
  const DAY_MS = 24 * 60 * 60 * 1000;
  const PERIOD_MS = 14 * DAY_MS;

  // ---- State ----
  let shifts = load(STORE_KEY, []);
  let settings = load(SETTINGS_KEY, null);
  if (!settings) {
    // Default anchor: most recent Sunday, so periods start on a Sunday.
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - d.getDay());
    settings = { periodStart: toDateInput(d), rounding: 1 };
    save(SETTINGS_KEY, settings);
  }
  let periodOffset = 0; // 0 = current period, -1 = previous, etc.
  let timerInterval = null;

  // ---- Elements ----
  const el = (id) => document.getElementById(id);
  const punchBtn = el('punchBtn');
  const statusText = el('statusText');
  const liveTimer = el('liveTimer');
  const punchHint = el('punchHint');
  const periodRange = el('periodRange');
  const periodTotal = el('periodTotal');
  const weekBreakdown = el('weekBreakdown');
  const shiftList = el('shiftList');
  const emptyState = el('emptyState');

  // ---- Helpers ----
  function load(key, fallback) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch {
      return fallback;
    }
  }
  function save(key, val) {
    localStorage.setItem(key, JSON.stringify(val));
  }
  function persist() { save(STORE_KEY, shifts); }

  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  function activeShift() {
    return shifts.find((s) => s.end == null) || null;
  }

  // Round a duration (ms) to nearest `rounding` minutes, return hours (number).
  function durationHours(start, end) {
    if (end == null) end = Date.now();
    let minutes = (end - start) / 60000;
    const r = settings.rounding || 1;
    if (r > 1) minutes = Math.round(minutes / r) * r;
    return Math.max(0, minutes / 60);
  }

  function fmtHours(h) { return h.toFixed(2); }

  function toDateInput(d) {
    const p = (n) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
  }
  function toDateTimeInput(ms) {
    const d = new Date(ms);
    const p = (n) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`;
  }
  function fmtClock(ms) {
    return new Date(ms).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  }
  function fmtDayLong(ms) {
    return new Date(ms).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' });
  }
  function fmtShort(ms) {
    return new Date(ms).toLocaleDateString([], { month: 'short', day: 'numeric' });
  }

  // Anchor (local midnight of configured pay-period start).
  function anchorMs() {
    const [y, m, d] = settings.periodStart.split('-').map(Number);
    return new Date(y, m - 1, d, 0, 0, 0, 0).getTime();
  }

  // Returns {start, end} ms for the period currently being viewed.
  function currentPeriod() {
    const anchor = anchorMs();
    const now = Date.now();
    const idx = Math.floor((now - anchor) / PERIOD_MS) + periodOffset;
    const start = anchor + idx * PERIOD_MS;
    return { start, end: start + PERIOD_MS, idx };
  }

  // ---- Rendering ----
  function render() {
    renderPunch();
    renderPeriod();
    renderList();
  }

  function renderPunch() {
    const active = activeShift();
    if (active) {
      statusText.textContent = 'Punched in';
      liveTimer.hidden = false;
      punchBtn.textContent = 'Punch Out';
      punchBtn.classList.remove('punch-in');
      punchBtn.classList.add('punch-out');
      punchHint.textContent = `Since ${fmtClock(active.start)}`;
      startTimer();
    } else {
      statusText.textContent = 'Punched out';
      liveTimer.hidden = true;
      punchBtn.textContent = 'Punch In';
      punchBtn.classList.add('punch-in');
      punchBtn.classList.remove('punch-out');
      punchHint.textContent = '';
      stopTimer();
    }
  }

  function startTimer() {
    stopTimer();
    const tick = () => {
      const active = activeShift();
      if (!active) return stopTimer();
      const total = Math.floor((Date.now() - active.start) / 1000);
      const h = String(Math.floor(total / 3600)).padStart(2, '0');
      const m = String(Math.floor((total % 3600) / 60)).padStart(2, '0');
      const s = String(total % 60).padStart(2, '0');
      liveTimer.textContent = `${h}:${m}:${s}`;
    };
    tick();
    timerInterval = setInterval(tick, 1000);
  }
  function stopTimer() {
    if (timerInterval) clearInterval(timerInterval);
    timerInterval = null;
  }

  // Shifts whose start falls within [start, end).
  function shiftsInPeriod(start, end) {
    return shifts
      .filter((s) => s.start >= start && s.start < end)
      .sort((a, b) => b.start - a.start);
  }

  function renderPeriod() {
    const { start, end } = currentPeriod();
    const inPeriod = shiftsInPeriod(start, end);

    periodRange.textContent = `${fmtShort(start)} – ${fmtShort(end - DAY_MS)}` +
      (periodOffset === 0 ? ' (current)' : '');

    const total = inPeriod.reduce((sum, s) => sum + durationHours(s.start, s.end), 0);
    periodTotal.innerHTML = `${fmtHours(total)} <span>hrs</span>`;

    const mid = start + 7 * DAY_MS;
    const week1 = inPeriod.filter((s) => s.start < mid).reduce((a, s) => a + durationHours(s.start, s.end), 0);
    const week2 = inPeriod.filter((s) => s.start >= mid).reduce((a, s) => a + durationHours(s.start, s.end), 0);
    weekBreakdown.innerHTML = `
      <div class="week-box"><div class="label">Week 1 (${fmtShort(start)})</div><div class="val">${fmtHours(week1)}</div></div>
      <div class="week-box"><div class="label">Week 2 (${fmtShort(mid)})</div><div class="val">${fmtHours(week2)}</div></div>
    `;
  }

  function renderList() {
    const { start, end } = currentPeriod();
    const inPeriod = shiftsInPeriod(start, end);
    shiftList.innerHTML = '';
    emptyState.hidden = inPeriod.length > 0;

    let lastDay = '';
    for (const s of inPeriod) {
      const dayKey = new Date(s.start).toDateString();
      if (dayKey !== lastDay) {
        const label = document.createElement('div');
        label.className = 'day-group-label';
        label.textContent = fmtDayLong(s.start);
        shiftList.appendChild(label);
        lastDay = dayKey;
      }

      const item = document.createElement('div');
      item.className = 'shift-item' + (s.end == null ? ' active' : '');
      const timeStr = s.end == null
        ? `${fmtClock(s.start)} – in progress`
        : `${fmtClock(s.start)} – ${fmtClock(s.end)}`;
      item.innerHTML = `
        <div class="shift-main">
          <div class="shift-date">${fmtDayLong(s.start)}</div>
          <div class="shift-time">${timeStr}</div>
          ${s.note ? `<div class="shift-note">${escapeHtml(s.note)}</div>` : ''}
        </div>
        <div class="shift-hours">${fmtHours(durationHours(s.start, s.end))} h</div>
      `;
      item.addEventListener('click', () => openEdit(s.id));
      shiftList.appendChild(item);
    }
  }

  function escapeHtml(str) {
    return str.replace(/[&<>"']/g, (c) => (
      { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
    ));
  }

  // ---- Actions ----
  function togglePunch() {
    const active = activeShift();
    if (active) {
      active.end = Date.now();
    } else {
      shifts.push({ id: uid(), start: Date.now(), end: null, note: '' });
      periodOffset = 0; // jump to current period on punch in
    }
    persist();
    render();
  }

  // ---- Settings dialog ----
  const settingsDialog = el('settingsDialog');
  el('settingsBtn').addEventListener('click', () => {
    el('periodStartInput').value = settings.periodStart;
    el('roundingInput').value = String(settings.rounding || 1);
    settingsDialog.showModal();
  });
  settingsDialog.addEventListener('close', () => {
    if (settingsDialog.returnValue !== 'save') return;
    const ps = el('periodStartInput').value;
    if (ps) settings.periodStart = ps;
    settings.rounding = Number(el('roundingInput').value) || 1;
    save(SETTINGS_KEY, settings);
    periodOffset = 0;
    render();
  });

  // ---- Edit / Add dialog ----
  const editDialog = el('editDialog');
  function openEdit(id) {
    const s = shifts.find((x) => x.id === id);
    el('editTitle').textContent = 'Edit Shift';
    el('editId').value = id;
    el('editStart').value = toDateTimeInput(s.start);
    el('editEnd').value = s.end != null ? toDateTimeInput(s.end) : '';
    el('editNote').value = s.note || '';
    el('deleteShift').style.display = '';
    editDialog.showModal();
  }
  el('addManualBtn').addEventListener('click', () => {
    el('editTitle').textContent = 'Add Shift';
    el('editId').value = '';
    const now = new Date();
    now.setMinutes(0, 0, 0);
    el('editStart').value = toDateTimeInput(now.getTime());
    el('editEnd').value = toDateTimeInput(now.getTime() + 8 * 3600 * 1000);
    el('editNote').value = '';
    el('deleteShift').style.display = 'none';
    editDialog.showModal();
  });

  el('deleteShift').addEventListener('click', () => {
    const id = el('editId').value;
    shifts = shifts.filter((s) => s.id !== id);
    persist();
    editDialog.close('deleted');
    render();
  });

  editDialog.addEventListener('close', () => {
    if (editDialog.returnValue !== 'save') return;
    const id = el('editId').value;
    const startVal = el('editStart').value;
    const endVal = el('editEnd').value;
    if (!startVal) return;
    const start = new Date(startVal).getTime();
    const end = endVal ? new Date(endVal).getTime() : null;
    if (end != null && end < start) {
      alert('End time must be after start time.');
      return;
    }
    const note = el('editNote').value.trim();
    if (id) {
      const s = shifts.find((x) => x.id === id);
      s.start = start; s.end = end; s.note = note;
    } else {
      shifts.push({ id: uid(), start, end, note });
    }
    persist();
    render();
  });

  // ---- Period navigation ----
  el('prevPeriod').addEventListener('click', () => { periodOffset -= 1; render(); });
  el('nextPeriod').addEventListener('click', () => { if (periodOffset < 0) { periodOffset += 1; render(); } });

  // ---- Export ----
  el('exportBtn').addEventListener('click', exportCsv);
  function exportCsv() {
    const rows = [['Date', 'Start', 'End', 'Hours', 'Note']];
    [...shifts].sort((a, b) => a.start - b.start).forEach((s) => {
      rows.push([
        new Date(s.start).toLocaleDateString(),
        new Date(s.start).toLocaleString(),
        s.end != null ? new Date(s.end).toLocaleString() : '',
        fmtHours(durationHours(s.start, s.end)),
        (s.note || '').replace(/"/g, '""'),
      ]);
    });
    const csv = rows.map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `shifts-${toDateInput(new Date())}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  punchBtn.addEventListener('click', togglePunch);

  // Re-render when returning to the tab (keeps live totals fresh).
  document.addEventListener('visibilitychange', () => { if (!document.hidden) render(); });

  // ---- Service worker (offline) ----
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js').catch(() => {});
    });
  }

  render();
})();

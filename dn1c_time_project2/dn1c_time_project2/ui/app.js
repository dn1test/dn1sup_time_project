'use strict';
/* dn1c_time_project2/ui/app.js — логика окна статистики.
   Данные приходят из Ruby: window.updateUI(payload) раз в 5 с и по кнопкам. */

var state = null;

var STATUS = {
  active: { text: 'Активен', cls: 'text-bg-success' },
  idle: { text: 'Бездействие', cls: 'text-bg-secondary' },
  paused: { text: 'Пауза', cls: 'text-bg-warning' },
  off: { text: 'Выключен', cls: 'text-bg-secondary' }
};

var WD_SHORT = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

function el(id) { return document.getElementById(id); }

function fmt(sec) {
  sec = Math.round(Number(sec) || 0);
  var h = Math.floor(sec / 3600);
  var m = Math.round((sec % 3600) / 60);
  if (h > 0) return h + ' ч ' + m + ' мин';
  if (m > 0) return m + ' мин';
  return sec + ' с';
}

function callRuby(name, param) {
  try { sketchup.call_ruby(name, param || ''); } catch (e) { /* мост ещё не готов */ }
}

/* ---------------- сводка ---------------- */

function renderSummary(data) {
  var st = STATUS[data.status] || STATUS.off;
  var badge = el('status');
  badge.textContent = st.text;
  badge.className = 'badge ' + st.cls;

  var file = data.current
    ? (data.folder ? data.folder + ' \\ ' : '') + data.current
    : 'Модель не сохранена';
  el('file').textContent = file;
  el('file').title = file;

  var stats = data.stats;
  el('today').textContent = fmt(stats ? stats.today_seconds : 0);
  el('session').textContent = fmt(data.session_seconds);
  el('total').textContent = fmt(stats ? stats.total_seconds : 0);

  el('pauseBtn').innerHTML = data.paused ? '&#9654; Продолжить' : '&#9208; Пауза';

  var idle = el('idle');
  if (document.activeElement !== idle) idle.value = data.idle_minutes;
}

function renderProjects(data) {
  var sel = el('project');
  var names = data.projects || [];
  var current = Array.prototype.map.call(sel.options, function (o) { return o.value; }).join('\n');
  var next = names.join('\n');
  if (current !== next) {
    sel.innerHTML = '';
    names.forEach(function (n) {
      var opt = document.createElement('option');
      opt.value = n;
      opt.textContent = n;
      sel.appendChild(opt);
    });
  }
  if (data.selected) sel.value = data.selected;
}

/* ---------------- по дням (таблица) ---------------- */

function renderDays(stats) {
  var body = el('daysBody');
  body.innerHTML = '';
  var rows = (stats && stats.days) ? stats.days.slice(0, 30) : [];
  if (!rows.length) {
    body.innerHTML = '<tr><td colspan="4" class="text-secondary">Пока нет данных — поработайте над проектом</td></tr>';
    return;
  }
  var max = 1;
  rows.forEach(function (r) { if (r.seconds > max) max = r.seconds; });
  rows.forEach(function (r) {
    var pct = Math.round((r.seconds / max) * 100);
    var tr = document.createElement('tr');
    tr.innerHTML =
      '<td class="text-nowrap">' + r.date + '</td>' +
      '<td>' + r.weekday + '</td>' +
      '<td><div class="progress" style="height:12px"><div class="progress-bar" style="width:' + pct + '%"></div></div></td>' +
      '<td class="text-end text-nowrap">' + fmt(r.seconds) + '</td>';
    body.appendChild(tr);
  });
}

/* ---------------- столбчатые графики (часы / дни недели) ---------------- */

function renderBars(chartId, labelId, values, labels) {
  var chart = el(chartId);
  var axis = el(labelId);
  chart.innerHTML = '';
  axis.innerHTML = '';
  var max = 1;
  values.forEach(function (v) { if (v > max) max = v; });

  values.forEach(function (v, i) {
    var col = document.createElement('div');
    col.className = 'bar-col';
    col.title = labels[i] + ' — ' + fmt(v);
    if (v > 0) {
      var bar = document.createElement('div');
      bar.className = 'bar';
      bar.style.height = Math.max(2, Math.round((v / max) * 100)) + '%';
      col.appendChild(bar);
    }
    chart.appendChild(col);

    var lab = document.createElement('div');
    lab.textContent = labels[i];
    axis.appendChild(lab);
  });
}

function renderHours(stats) {
  var hours = (stats && stats.hours) ? stats.hours : [];
  var labels = [];
  for (var h = 0; h < 24; h++) labels.push(String(h));
  renderBars('hoursChart', 'hoursLabels', hours, labels);
}

function renderWeekdays(stats) {
  var wd = (stats && stats.weekdays) ? stats.weekdays : [];
  renderBars('weekdaysChart', 'weekdaysLabels', wd, WD_SHORT);
}

/* ---------------- точка входа от Ruby ---------------- */

window.updateUI = function (data) {
  state = data;
  renderSummary(data);
  renderProjects(data);
  renderDays(data.stats);
  renderHours(data.stats);
  renderWeekdays(data.stats);
};

window.addEventListener('load', function () {
  document.querySelectorAll('[data-tab]').forEach(function (a) {
    a.addEventListener('click', function (e) {
      e.preventDefault();
      document.querySelectorAll('[data-tab]').forEach(function (x) { x.classList.remove('active'); });
      a.classList.add('active');
      ['days', 'hours', 'weekdays'].forEach(function (t) {
        el('tab-' + t).classList.toggle('d-none', t !== a.getAttribute('data-tab'));
      });
    });
  });

  el('refreshBtn').addEventListener('click', function () { callRuby('get_stats'); });
  el('pauseBtn').addEventListener('click', function () { callRuby('toggle_pause'); });
  el('folderBtn').addEventListener('click', function () { callRuby('open_folder'); });
  el('project').addEventListener('change', function () { callRuby('select_project', el('project').value); });
  el('idle').addEventListener('change', function () { callRuby('set_idle_minutes', el('idle').value); });

  setInterval(function () { callRuby('get_stats'); }, 5000);
  callRuby('ready');
});

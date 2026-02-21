import { fetchJSON } from '/utils.js';

const NS  = 'http://www.w3.org/2000/svg';
const PAD = { top: 10, right: 12, bottom: 28, left: 36 };
// Font family is read from the same CSS var Tailwind emits from @theme.
const fontMono = () =>
  getComputedStyle(document.documentElement).getPropertyValue('--font-mono').trim()
  || 'JetBrains Mono, monospace';

const LABEL = () => ({ 'font-family': fontMono(), 'font-size': '9' });

// Unified SVG element factory — third arg sets textContent.
function svgEl(tag, attrs, text) {
  const e = document.createElementNS(NS, tag);
  for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
  if (text != null) e.textContent = text;
  return e;
}

function drawChart(svg, data, W) {
  const H      = Math.round(W * 0.21);  // ~120px at 560px wide
  const innerW = W - PAD.left - PAD.right;
  const innerH = H - PAD.top  - PAD.bottom;

  const counts = data.map(d => d.count);
  const minV   = Math.min(...counts);
  const maxV   = Math.max(...counts);
  const yRange = maxV === minV ? 1 : maxV - minV;
  const yPad   = Math.max(1, Math.round(yRange * 0.15));
  const yMin   = Math.max(0, minV - yPad);
  const yMax   = maxV + yPad;

  const xScale = i => PAD.left + (i / (data.length - 1)) * innerW;
  const yScale = v => PAD.top  + (1 - (v - yMin) / (yMax - yMin)) * innerH;

  const cs      = getComputedStyle(document.documentElement);
  const green   = cs.getPropertyValue('--color-green').trim()     || '#a6e3a1';
  const surface = cs.getPropertyValue('--color-surface-1').trim() || '#2e3d34';
  const subtext = cs.getPropertyValue('--color-subtext-0').trim() || '#93b09a';

  svg.setAttribute('viewBox', `0 0 ${W} ${H}`);
  svg.setAttribute('height', H);
  svg.innerHTML = '';

  // ── Grid lines + Y-axis labels (bottom, mid, top) ────────────────────────
  for (let t = 0; t <= 2; t++) {
    const yv = yMin + (t / 2) * (yMax - yMin);
    const y  = yScale(yv);
    svg.appendChild(svgEl('line', {
      x1: PAD.left, y1: y, x2: PAD.left + innerW, y2: y,
      stroke: surface, 'stroke-width': 1,
    }));
    svg.appendChild(svgEl('text',
      { ...LABEL(), x: PAD.left - 5, y: y + 4, 'text-anchor': 'end', fill: subtext },
      Math.round(yv),
    ));
  }

  // ── X-axis date labels (first, middle, last) ──────────────────────────────
  const anchors = ['start', 'middle', 'end'];
  [0, Math.floor((data.length - 1) / 2), data.length - 1].forEach((i, pos) => {
    svg.appendChild(svgEl('text',
      { ...LABEL(), x: xScale(i), y: H - 6, 'text-anchor': anchors[pos], fill: subtext },
      data[i].date.slice(5),  // MM-DD
    ));
  });

  // ── Filled area ───────────────────────────────────────────────────────────
  const baseline   = yScale(yMin);
  const areaPoints = [
    `${xScale(0)},${baseline}`,
    ...data.map((d, i) => `${xScale(i)},${yScale(d.count)}`),
    `${xScale(data.length - 1)},${baseline}`,
  ].join(' ');
  svg.appendChild(svgEl('polygon', { points: areaPoints, fill: green, 'fill-opacity': '0.08' }));

  // ── Line ──────────────────────────────────────────────────────────────────
  svg.appendChild(svgEl('polyline', {
    points: data.map((d, i) => `${xScale(i)},${yScale(d.count)}`).join(' '),
    fill: 'none', stroke: green, 'stroke-width': '1.5',
    'stroke-linejoin': 'round', 'stroke-linecap': 'round',
  }));

  // ── Dots (only when sparse enough to not clutter) ────────────────────────
  if (data.length <= 14) {
    data.forEach((d, i) => svg.appendChild(svgEl('circle', {
      cx: xScale(i), cy: yScale(d.count), r: 2.5, fill: green,
    })));
  }

  // ── Latest-value annotation ───────────────────────────────────────────────
  const last = data[data.length - 1];
  svg.appendChild(svgEl('text',
    { ...LABEL(), x: xScale(data.length - 1) - 4, y: yScale(last.count) - 6,
      'text-anchor': 'end', fill: green },
    last.count,
  ));
}

export async function loadChart() {
  const svg   = document.getElementById('records-chart');
  const empty = document.getElementById('chart-empty');
  if (!svg) return;

  let data;
  try {
    data = await fetchJSON('/cache/records.json');
  } catch {
    svg.hidden   = true;
    empty.hidden = false;
    return;
  }

  if (!Array.isArray(data) || data.length < 2) {
    svg.hidden   = true;
    empty.hidden = false;
    return;
  }

  svg.setAttribute('width', '100%');
  const draw = () => drawChart(svg, data, svg.parentElement.clientWidth || 560);
  draw();

  // Re-draw on resize (orientation change, window resize, etc.)
  new ResizeObserver(draw).observe(svg.parentElement);
}

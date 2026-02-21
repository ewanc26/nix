import { fetchJSON } from '/utils.js';

function set(id, text, cls) {
  const el = document.getElementById(id);
  if (!el) return;
  el.textContent = text;
  el.className = 'kv-val' + (cls ? ' ' + cls : '');
}

// Format elapsed seconds as locale-aware h mm ss.
function formatUptime(totalSeconds) {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  const pad = new Intl.NumberFormat(undefined, { minimumIntegerDigits: 2 });
  return `${h}h ${pad.format(m)}m ${pad.format(s)}s`;
}

export async function loadUptime() {
  try {
    const r = await fetch('/start-time');
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const startEpoch = parseInt(await r.text(), 10);
    if (!Number.isFinite(startEpoch)) throw new Error('bad epoch');

    const tick = () => {
      const elapsed = Math.floor(Date.now() / 1000) - startEpoch;
      set('val-uptime', formatUptime(Math.max(0, elapsed)));
    };
    tick();
    setInterval(tick, 1000);
  } catch {
    set('val-uptime', '—');
  }
}

export async function loadStatus() {
  // health
  try {
    const h = await fetchJSON('/xrpc/_health');
    set('val-reachable', '✓ online', 'ok');
    set('val-version', h.version ?? 'unknown');
  } catch {
    set('val-reachable', '✗ unreachable', 'err');
    set('val-version', '—', 'err');
  }

  // description
  try {
    const d = await fetchJSON('/xrpc/com.atproto.server.describeServer');
    set('val-did', d.did ?? '—');
    set('val-invite', d.inviteCodeRequired ? 'yes' : 'no',
      d.inviteCodeRequired ? 'warn' : 'ok');
  } catch {
    set('val-did', '—');
    set('val-invite', '—');
  }

  // account count — paginate com.atproto.sync.listRepos (public, no auth)
  try {
    let cursor, total = 0;
    do {
      const url = '/xrpc/com.atproto.sync.listRepos?limit=1000' +
                  (cursor ? '&cursor=' + encodeURIComponent(cursor) : '');
      const r = await fetchJSON(url);
      total += (r.repos ?? []).length;
      cursor = r.cursor;
    } while (cursor);
    set('val-accounts', total.toString());
  } catch {
    set('val-accounts', '—');
  }
}

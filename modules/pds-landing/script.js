async function fetchJSON(path) {
  const r = await fetch(path);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}

function set(id, text, cls) {
  const el = document.getElementById(id);
  if (!el) return;
  el.textContent = text;
  el.className = 'kv-val' + (cls ? ' ' + cls : '');
}

async function loadStatus() {
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

  // account count
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

loadStatus();

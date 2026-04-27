/** Minimal hosted pages after Checkout (Stripe redirects here). */

export function successPageHtml(sessionId: string | undefined): string {
  const safeId = sessionId ? escapeHtml(sessionId) : '';
  const deep =
    sessionId != null && sessionId.length > 0
      ? `walletvaval://stripe-return?session_id=${encodeURIComponent(sessionId)}`
      : 'walletvaval://stripe-return';
  const hrefAttr = deep.includes("'") ? deep.replace(/'/g, '%27') : deep;
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Payment successful</title>
  <style>
    :root { color-scheme: dark; }
    body {
      margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: #0d1b2e; color: #e3e8ef;
    }
    .card {
      max-width: 420px; padding: 2rem; border-radius: 16px;
      background: #1a2a3e; box-shadow: 0 12px 40px rgba(0,0,0,.35);
      text-align: center;
    }
    h1 { font-size: 1.35rem; margin: 0 0 0.75rem; color: #90caf9; }
    p { margin: 0 0 1.25rem; line-height: 1.5; font-size: 0.95rem; color: rgba(255,255,255,.82); }
    .session { font-size: 0.75rem; word-break: break-all; opacity: 0.55; margin-bottom: 1.25rem; }
    a.btn {
      display: inline-block; padding: 0.85rem 1.5rem; border-radius: 12px;
      background: #2979ff; color: #fff; text-decoration: none; font-weight: 600;
    }
    a.btn:hover { filter: brightness(1.08); }
    .hint { margin-top: 1rem; font-size: 0.8rem; opacity: 0.6; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Payment successful</h1>
    <p>Your access payment completed. Open the Wallet Vaval app to continue.</p>
    ${safeId ? `<div class="session">Session: ${safeId}</div>` : ''}
    <a class="btn" href='${hrefAttr}'>Open Wallet Vaval</a>
    <p class="hint">If the app does not open, switch back to it from your recent apps.</p>
  </div>
  <script>
    (function () {
      var href = ${JSON.stringify(deep)};
      if (href) setTimeout(function () { window.location.href = href; }, 1200);
    })();
  </script>
</body>
</html>`;
}

export function canceledPageHtml(): string {
  const deep = 'walletvaval://stripe-cancel';
  const hrefAttr = deep.includes("'") ? deep.replace(/'/g, '%27') : deep;
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Payment canceled</title>
  <style>
    :root { color-scheme: dark; }
    body {
      margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: #0d1b2e; color: #e3e8ef;
    }
    .card {
      max-width: 420px; padding: 2rem; border-radius: 16px;
      background: #1a2a3e; box-shadow: 0 12px 40px rgba(0,0,0,.35);
      text-align: center;
    }
    h1 { font-size: 1.35rem; margin: 0 0 0.75rem; color: #ffb74d; }
    p { margin: 0 0 1.25rem; line-height: 1.5; font-size: 0.95rem; color: rgba(255,255,255,.82); }
    a.btn {
      display: inline-block; padding: 0.85rem 1.5rem; border-radius: 12px;
      background: #37474f; color: #fff; text-decoration: none; font-weight: 600;
    }
    a.btn:hover { filter: brightness(1.12); }
  </style>
</head>
<body>
  <div class="card">
    <h1>Payment canceled</h1>
    <p>No charge was made. You can close this page and return to the app when you are ready.</p>
    <a class="btn" href='${hrefAttr}'>Return to Wallet Vaval</a>
  </div>
</body>
</html>`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

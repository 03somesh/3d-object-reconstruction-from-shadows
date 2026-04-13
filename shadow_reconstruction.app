<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ShadowCast — 3D Object Height Reconstruction</title>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
<style>
  :root {
    --bg:      #08090d;
    --surface: #0f1117;
    --surface2:#161923;
    --border:  rgba(255,255,255,0.06);
    --gold:    #f5a623;
    --gold2:   #ffd280;
    --blue:    #4fa3e0;
    --green:   #3ecf8e;
    --red:     #ff6b6b;
    --text:    #e4e8f0;
    --muted:   #5a6478;
    --glow:    rgba(245,166,35,0.18);
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: 'Space Grotesk', sans-serif;
    background: var(--bg);
    color: var(--text);
    min-height: 100vh;
  }

  /* Background grid */
  body::before {
    content: '';
    position: fixed; inset: 0;
    background-image:
      linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px);
    background-size: 44px 44px;
    pointer-events: none; z-index: 0;
  }

  body::after {
    content: '';
    position: fixed; inset: 0;
    background:
      radial-gradient(ellipse 55% 45% at 15% 15%, rgba(245,166,35,0.07) 0%, transparent 65%),
      radial-gradient(ellipse 40% 55% at 85% 85%, rgba(79,163,224,0.06) 0%, transparent 65%);
    pointer-events: none; z-index: 0;
  }

  .wrap { max-width: 1080px; margin: 0 auto; padding: 0 22px; position: relative; z-index: 1; }

  /* ── Header ── */
  header { padding: 38px 0 18px; text-align: center; }

  .badge {
    display: inline-flex; align-items: center; gap: 7px;
    background: rgba(245,166,35,0.1);
    border: 1px solid rgba(245,166,35,0.28);
    border-radius: 100px; padding: 5px 16px;
    font-size: 11px; font-weight: 500; letter-spacing: 0.09em;
    text-transform: uppercase; color: var(--gold);
    margin-bottom: 18px;
    animation: fadeD 0.6s ease both;
  }

  .badge-dot { width:6px; height:6px; background:var(--gold); border-radius:50%; animation: pulse 2s infinite; }

  h1 {
    font-size: clamp(2rem, 5.5vw, 3.8rem);
    font-weight: 700; line-height: 1.08;
    letter-spacing: -0.03em;
    animation: fadeD 0.6s 0.1s ease both;
  }

  h1 em { color: var(--gold); font-style: normal; }

  .sub {
    margin-top: 12px; font-size: 1rem; color: var(--muted);
    font-weight: 300; line-height: 1.65;
    max-width: 480px; margin-left: auto; margin-right: auto;
    animation: fadeD 0.6s 0.2s ease both;
  }

  /* ── Stats row ── */
  .stats {
    display: flex; justify-content: center; gap: 10px;
    flex-wrap: wrap; margin: 28px 0;
    animation: fadeD 0.6s 0.3s ease both;
  }

  .stat {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 12px; padding: 10px 20px; text-align: center;
  }

  .stat .v { font-family:'Space Mono',monospace; font-size:1.25rem; font-weight:700; color:var(--gold); }
  .stat .l { font-size:0.68rem; color:var(--muted); text-transform:uppercase; letter-spacing:0.06em; margin-top:2px; }

  /* ── Layout ── */
  .grid { display: grid; grid-template-columns: 1fr 360px; gap: 18px; margin-bottom: 55px; animation: fadeU 0.7s 0.4s ease both; }
  @media(max-width:760px){ .grid { grid-template-columns:1fr; } }

  /* ── Cards ── */
  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 18px; padding: 26px;
  }

  .ctitle {
    font-size: 0.72rem; font-weight: 600;
    letter-spacing: 0.1em; text-transform: uppercase;
    color: var(--muted); margin-bottom: 20px;
    display: flex; align-items: center; gap: 8px;
  }

  .ctitle::before { content:''; display:block; width:3px; height:13px; background:var(--gold); border-radius:4px; }

  /* ── Fields ── */
  .fgrid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
  @media(max-width:480px){ .fgrid { grid-template-columns:1fr; } }

  .field { display:flex; flex-direction:column; gap:5px; }

  .field label {
    font-size:0.74rem; font-weight:500; color:var(--muted);
    letter-spacing:0.04em; text-transform:uppercase;
    display:flex; justify-content:space-between;
  }

  .field label .hint { color:rgba(90,100,120,0.7); font-weight:400; text-transform:none; letter-spacing:0; }

  .rrow { display:flex; align-items:center; gap:10px; }

  input[type=range] {
    -webkit-appearance:none; flex:1; height:4px;
    background:var(--surface2); border-radius:4px; outline:none; cursor:pointer;
  }

  input[type=range]::-webkit-slider-thumb {
    -webkit-appearance:none; width:15px; height:15px;
    border-radius:50%; background:var(--gold);
    border:2px solid var(--bg);
    box-shadow:0 0 8px var(--glow);
    cursor:pointer; transition:transform 0.15s, box-shadow 0.15s;
  }

  input[type=range]::-webkit-slider-thumb:hover {
    transform:scale(1.3); box-shadow:0 0 16px var(--glow);
  }

  .rval {
    font-family:'Space Mono',monospace;
    font-size:0.92rem; font-weight:700;
    color:var(--gold); min-width:46px; text-align:right;
  }

  select {
    background:var(--surface2); border:1px solid var(--border);
    border-radius:10px; padding:9px 12px;
    color:var(--text); font-family:'Space Grotesk',sans-serif;
    font-size:0.9rem; outline:none; cursor:pointer;
    transition:border-color 0.2s;
  }

  select:focus { border-color:var(--gold); }

  /* Auto-compute hint */
  .auto-hint {
    font-size:0.7rem; color:rgba(90,100,120,0.8);
    font-style:italic; margin-top:4px;
  }

  /* ── Button ── */
  .btn {
    width:100%; margin-top:20px; padding:15px;
    background:var(--gold); color:#08090d;
    font-family:'Space Grotesk',sans-serif;
    font-size:0.98rem; font-weight:700;
    letter-spacing:0.04em; border:none;
    border-radius:12px; cursor:pointer;
    position:relative; overflow:hidden;
    transition:transform 0.15s, box-shadow 0.15s;
  }

  .btn::before {
    content:''; position:absolute; inset:0;
    background:linear-gradient(135deg, rgba(255,255,255,0.18) 0%, transparent 55%);
    pointer-events:none;
  }

  .btn:hover { transform:translateY(-2px); box-shadow:0 8px 28px rgba(245,166,35,0.38); }
  .btn:active { transform:translateY(0); }

  /* ── Result panel ── */
  .rpanel { display:flex; flex-direction:column; gap:16px; }

  /* Height result */
  .hcard {
    background:var(--surface); border:1px solid var(--border);
    border-radius:18px; padding:26px; text-align:center;
    transition:border-color 0.4s;
  }

  .hlabel { font-size:0.68rem; font-weight:600; letter-spacing:0.1em; text-transform:uppercase; color:var(--muted); margin-bottom:8px; }

  .hval {
    font-family:'Space Mono',monospace;
    font-size:3.4rem; font-weight:700; line-height:1;
    color:var(--gold); transition:color 0.3s;
  }

  .hunit { font-size:1.4rem; color:var(--muted); }

  .hverdict { margin-top:8px; font-size:0.95rem; font-weight:500; color:var(--muted); }

  /* 3D visual */
  .vis-wrap {
    margin-top:16px; display:flex;
    align-items:flex-end; justify-content:center;
    gap:0; height:100px;
  }

  /* Feature importance */
  .coef-row {
    display:grid; grid-template-columns:130px 1fr 52px;
    align-items:center; gap:9px; margin-bottom:9px;
  }

  .coef-name { font-size:0.74rem; color:var(--muted); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }

  .bar-bg { background:var(--surface2); border-radius:4px; height:5px; overflow:hidden; }
  .bar-fill { height:100%; border-radius:4px; transition:width 0.7s cubic-bezier(.4,0,.2,1); }

  .coef-v { font-family:'Space Mono',monospace; font-size:0.72rem; font-weight:700; text-align:right; }

  /* Metrics grid */
  .mgrid { display:grid; grid-template-columns:1fr 1fr; gap:10px; }

  .mcell {
    background:var(--surface2); border-radius:12px;
    padding:14px 12px; text-align:center;
  }

  .mcell .mn { font-family:'Space Mono',monospace; font-size:1.5rem; font-weight:700; color:var(--gold); line-height:1; }
  .mcell .ml { font-size:0.66rem; color:var(--muted); margin-top:4px; text-transform:uppercase; letter-spacing:0.05em; }

  /* Shadow visual canvas */
  #shadowCanvas { border-radius:12px; margin-top:10px; }

  .placeholder { color:var(--muted); font-size:0.88rem; text-align:center; padding:28px 10px; line-height:1.6; }
  .ph-icon { font-size:2.4rem; margin-bottom:8px; opacity:0.35; }

  /* ── Animations ── */
  @keyframes fadeD { from{opacity:0;transform:translateY(-14px)} to{opacity:1;transform:translateY(0)} }
  @keyframes fadeU { from{opacity:0;transform:translateY(18px)} to{opacity:1;transform:translateY(0)} }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.35} }

  @keyframes countUp { from{opacity:0;transform:scale(0.8)} to{opacity:1;transform:scale(1)} }

  .footer {
    text-align:center; font-size:0.72rem; color:rgba(90,100,120,0.45);
    padding:0 20px 40px; line-height:1.7; position:relative; z-index:1;
  }
</style>
</head>
<body>
<div class="wrap">

  <header>
    <div class="badge"><div class="badge-dot"></div>Linear Regression · Shadow Physics · 1000 Samples</div>
    <h1>Shadow<em>Cast</em></h1>
    <p class="sub">Reconstruct object height from shadow measurements using a trained Linear Regression model.</p>
  </header>

  <div class="stats">
    <div class="stat"><div class="v">83.4%</div><div class="l">R² Score</div></div>
    <div class="stat"><div class="v">1.79m</div><div class="l">Mean Abs Error</div></div>
    <div class="stat"><div class="v">82.3%</div><div class="l">5-Fold CV R²</div></div>
    <div class="stat"><div class="v">1000</div><div class="l">Training Samples</div></div>
    <div class="stat"><div class="v">8</div><div class="l">Features</div></div>
  </div>

  <div class="grid">

    <!-- ── LEFT: inputs ── -->
    <div class="card">
      <div class="ctitle">Shadow & Sun Measurements</div>

      <div class="fgrid">

        <div class="field">
          <label>Sun Elevation <span class="hint">degrees</span></label>
          <div class="rrow">
            <input type="range" id="sun_elev" min="10" max="80" value="45" oninput="sync('sun_elev','sv_elev'); autoCompute()">
            <span class="rval" id="sv_elev">45</span>
          </div>
        </div>

        <div class="field">
          <label>Sun Azimuth <span class="hint">degrees</span></label>
          <div class="rrow">
            <input type="range" id="sun_az" min="0" max="359" value="180" oninput="sync('sun_az','sv_az')">
            <span class="rval" id="sv_az">180</span>
          </div>
        </div>

        <div class="field">
          <label>Time of Day <span class="hint">hour</span></label>
          <div class="rrow">
            <input type="range" id="tod" min="6" max="18" step="0.5" value="12" oninput="sync('tod','sv_tod'); autoCompute()">
            <span class="rval" id="sv_tod">12.0</span>
          </div>
        </div>

        <div class="field">
          <label>Shadow Length <span class="hint">metres</span></label>
          <div class="rrow">
            <input type="range" id="slen" min="0.2" max="60" step="0.1" value="10" oninput="sync('slen','sv_slen'); autoCompute()">
            <span class="rval" id="sv_slen">10.0</span>
          </div>
        </div>

        <div class="field">
          <label>Shadow Width <span class="hint">metres</span></label>
          <div class="rrow">
            <input type="range" id="swid" min="0.2" max="15" step="0.1" value="4" oninput="sync('swid','sv_swid'); autoCompute()">
            <span class="rval" id="sv_swid">4.0</span>
          </div>
        </div>

        <div class="field">
          <label>Shadow Area <span class="hint">m² — auto</span></label>
          <div class="rrow">
            <input type="range" id="sarea" min="0.1" max="200" step="0.1" value="40" oninput="sync('sarea','sv_sarea')">
            <span class="rval" id="sv_sarea">40.0</span>
          </div>
          <span class="auto-hint">Auto-computed from length × width</span>
        </div>

        <div class="field">
          <label>Aspect Ratio <span class="hint">len/wid — auto</span></label>
          <div class="rrow">
            <input type="range" id="aratio" min="0.5" max="16" step="0.01" value="2.5" oninput="sync('aratio','sv_aratio')">
            <span class="rval" id="sv_aratio">2.50</span>
          </div>
          <span class="auto-hint">Auto-computed from dimensions</span>
        </div>

        <div class="field">
          <label>Object Type</label>
          <select id="otype">
            <option value="0">🌳 Tree</option>
            <option value="1" selected>🏗️ Pole</option>
            <option value="2">🏢 Building</option>
            <option value="3">🧍 Person</option>
          </select>
        </div>

      </div>

      <button class="btn" onclick="predict(event)">⚡ Reconstruct Object Height</button>
    </div>

    <!-- ── RIGHT: results ── -->
    <div class="rpanel">

      <!-- Height output -->
      <div class="hcard" id="hcard">
        <div class="hlabel">Estimated Object Height</div>
        <div class="hval" id="hval">—<span class="hunit"> m</span></div>
        <div class="hverdict" id="hverdict">
          <div class="ph-icon">🌑</div>
          <div class="placeholder">Adjust measurements and click Reconstruct to estimate the object height.</div>
        </div>

        <!-- Shadow visual -->
        <canvas id="shadowCanvas" width="300" height="90" style="display:none"></canvas>
      </div>

      <!-- Feature importance -->
      <div class="card">
        <div class="ctitle">Feature Coefficients</div>
        <div id="coefChart"></div>
      </div>

      <!-- Metrics -->
      <div class="card">
        <div class="ctitle">Model Performance</div>
        <div class="mgrid">
          <div class="mcell"><div class="mn">83.4%</div><div class="ml">R² Score</div></div>
          <div class="mcell"><div class="mn">82.3%</div><div class="ml">5-Fold CV R²</div></div>
          <div class="mcell"><div class="mn">1.79m</div><div class="ml">Mean Abs Error</div></div>
          <div class="mcell"><div class="mn">2.32m</div><div class="ml">RMSE</div></div>
        </div>
      </div>

    </div>
  </div>
</div>

<p class="footer">
  🔬 Built on Shadow Physics Dataset · Linear Regression · Scikit-learn<br>
  Physics formula: Height = Shadow Length × tan(Sun Elevation) · For educational purposes only.
</p>

<script>
/* ── Embedded model from sklearn LinearRegression ── */
const MODEL = {
  intercept: 10.531365,
  coef: {
    sun_elevation_deg: 3.050054,
    sun_azimuth_deg:   0.072864,
    time_of_day_hr:    0.080154,
    shadow_length_m:   0.829417,
    shadow_width_m:    3.091301,
    shadow_area_m2:    2.270661,
    aspect_ratio:      1.375542,
    object_type:      -0.138780
  },
  mean: {
    sun_elevation_deg: 44.67215,
    sun_azimuth_deg:   182.648212,
    time_of_day_hr:    11.836675,
    shadow_length_m:   14.48281,
    shadow_width_m:    5.70849,
    shadow_area_m2:    75.491786,
    aspect_ratio:      2.888565,
    object_type:       1.16875
  },
  std: {
    sun_elevation_deg: 20.481977,
    sun_azimuth_deg:   104.152304,
    time_of_day_hr:    3.443147,
    shadow_length_m:   15.127681,
    shadow_width_m:    3.583769,
    shadow_area_m2:    72.16035,
    aspect_ratio:      2.667879,
    object_type:       1.071342
  }
};

const LABELS = {
  sun_elevation_deg: 'Sun Elevation',
  sun_azimuth_deg:   'Sun Azimuth',
  time_of_day_hr:    'Time of Day',
  shadow_length_m:   'Shadow Length',
  shadow_width_m:    'Shadow Width',
  shadow_area_m2:    'Shadow Area',
  aspect_ratio:      'Aspect Ratio',
  object_type:       'Object Type'
};

function sync(id, vid) {
  const v = parseFloat(document.getElementById(id).value);
  const el = document.getElementById(vid);
  if(id==='sun_elev'||id==='tod') el.textContent = v.toFixed(1);
  else if(id==='aratio')           el.textContent = v.toFixed(2);
  else                             el.textContent = v.toFixed(1);
}

function autoCompute() {
  const L = parseFloat(document.getElementById('slen').value);
  const W = parseFloat(document.getElementById('swid').value);
  const area  = Math.min(L * W, 200).toFixed(1);
  const ratio = Math.min(L / (W + 0.001), 16).toFixed(2);

  document.getElementById('sarea').value = area;
  document.getElementById('sv_sarea').textContent = area;
  document.getElementById('aratio').value = ratio;
  document.getElementById('sv_aratio').textContent = ratio;
}

/* Build feature coefficient chart */
function buildChart() {
  const coefs = MODEL.coef;
  const maxAbs = Math.max(...Object.values(coefs).map(Math.abs));
  const sorted = Object.entries(coefs).sort((a,b) => Math.abs(b[1]) - Math.abs(a[1]));
  const html = sorted.map(([feat, val]) => {
    const pct  = (Math.abs(val) / maxAbs * 100).toFixed(1);
    const col  = val >= 0 ? '#f5a623' : '#4fa3e0';
    const sign = val >= 0 ? '+' : '';
    return `
      <div class="coef-row">
        <span class="coef-name">${LABELS[feat]||feat}</span>
        <div class="bar-bg"><div class="bar-fill" style="width:${pct}%;background:${col}"></div></div>
        <span class="coef-v" style="color:${col}">${sign}${val.toFixed(3)}</span>
      </div>`;
  }).join('');
  document.getElementById('coefChart').innerHTML = html;
}

/* Draw shadow illustration */
function drawShadow(height, shadowLen) {
  const canvas = document.getElementById('shadowCanvas');
  const ctx = canvas.getContext('2d');
  const W = canvas.width, H = canvas.height;
  ctx.clearRect(0,0,W,H);

  // Ground line
  ctx.strokeStyle = 'rgba(245,166,35,0.25)';
  ctx.lineWidth = 1;
  ctx.setLineDash([4,4]);
  ctx.beginPath(); ctx.moveTo(20, H-20); ctx.lineTo(W-20, H-20); ctx.stroke();
  ctx.setLineDash([]);

  // Scale
  const maxH = 20, maxS = 60;
  const hPx = Math.min((height / maxH) * (H - 35), H - 35);
  const sPx = Math.min((shadowLen / maxS) * (W * 0.55), W * 0.55);

  const objX = 60, groundY = H - 20;

  // Shadow
  const grad = ctx.createLinearGradient(objX, groundY, objX + sPx, groundY);
  grad.addColorStop(0, 'rgba(245,166,35,0.35)');
  grad.addColorStop(1, 'rgba(245,166,35,0.02)');
  ctx.fillStyle = grad;
  ctx.fillRect(objX, groundY - 6, sPx, 6);

  // Object (vertical bar)
  ctx.fillStyle = 'rgba(245,166,35,0.9)';
  ctx.fillRect(objX - 4, groundY - hPx, 8, hPx);

  // Height label
  ctx.fillStyle = '#f5a623';
  ctx.font = 'bold 11px Space Mono, monospace';
  ctx.textAlign = 'center';
  ctx.fillText(`${height.toFixed(1)}m`, objX, groundY - hPx - 6);

  // Shadow label
  ctx.fillStyle = 'rgba(245,166,35,0.6)';
  ctx.font = '9px Space Grotesk, sans-serif';
  ctx.fillText(`shadow: ${shadowLen.toFixed(1)}m`, objX + sPx/2, groundY + 12);

  // Sun ray
  ctx.strokeStyle = 'rgba(255,210,128,0.4)';
  ctx.lineWidth = 1.5;
  ctx.setLineDash([3,3]);
  ctx.beginPath();
  ctx.moveTo(W - 30, 15);
  ctx.lineTo(objX, groundY - hPx);
  ctx.stroke();
  ctx.setLineDash([]);

  // Sun circle
  ctx.fillStyle = 'rgba(255,210,128,0.9)';
  ctx.beginPath(); ctx.arc(W-30, 15, 7, 0, Math.PI*2); ctx.fill();
}

/* Main prediction */
function predict(e) {
  // ripple
  const btn = e.currentTarget;
  const rip = document.createElement('span');
  rip.style.cssText = `position:absolute;border-radius:50%;background:rgba(255,255,255,0.25);
    width:50px;height:50px;left:${e.offsetX-25}px;top:${e.offsetY-25}px;
    animation:none;transform:scale(0);opacity:0.6;pointer-events:none;transition:transform 0.5s,opacity 0.5s;`;
  btn.appendChild(rip);
  requestAnimationFrame(() => { rip.style.transform='scale(5)'; rip.style.opacity='0'; });
  setTimeout(() => rip.remove(), 600);

  const raw = {
    sun_elevation_deg: +document.getElementById('sun_elev').value,
    sun_azimuth_deg:   +document.getElementById('sun_az').value,
    time_of_day_hr:    +document.getElementById('tod').value,
    shadow_length_m:   +document.getElementById('slen').value,
    shadow_width_m:    +document.getElementById('swid').value,
    shadow_area_m2:    +document.getElementById('sarea').value,
    aspect_ratio:      +document.getElementById('aratio').value,
    object_type:       +document.getElementById('otype').value,
  };

  // Linear Regression: y = intercept + sum(coef_i * (x_i - mean_i) / std_i)
  let y = MODEL.intercept;
  for(const [feat, val] of Object.entries(raw)) {
    const scaled = (val - MODEL.mean[feat]) / MODEL.std[feat];
    y += scaled * MODEL.coef[feat];
  }
  const height = Math.max(0.1, y);

  // Update display
  const hcard  = document.getElementById('hcard');
  const hval   = document.getElementById('hval');
  const hverdict = document.getElementById('hverdict');
  const canvas   = document.getElementById('shadowCanvas');

  // Animate number
  animCount(hval, height);

  // Verdict
  let verdict, color;
  if(height < 2)       { verdict = '🧍 Person-scale object (0–2m)';     color = '#3ecf8e'; }
  else if(height < 6)  { verdict = '🌳 Small tree or shrub (2–6m)';      color = '#3ecf8e'; }
  else if(height < 12) { verdict = '🏗️ Utility pole or tall tree (6–12m)'; color = '#f5a623'; }
  else if(height < 25) { verdict = '🏢 Building or large tree (12–25m)'; color = '#f5a623'; }
  else                 { verdict = '🏙️ Tall structure / skyscraper (25m+)'; color = '#ff6b6b'; }

  hverdict.style.color = color;
  hverdict.textContent = verdict;
  hcard.style.borderColor = color + '55';

  // Draw canvas
  canvas.style.display = 'block';
  drawShadow(height, raw.shadow_length_m);
}

function animCount(el, target) {
  const dur = 700, step = 16;
  let t = 0;
  const timer = setInterval(() => {
    t += step;
    const eased = target * (1 - Math.pow(1 - Math.min(t/dur,1), 3));
    el.innerHTML = eased.toFixed(2) + '<span class="hunit"> m</span>';
    if(t >= dur) { el.innerHTML = target.toFixed(2) + '<span class="hunit"> m</span>'; clearInterval(timer); }
  }, step);
}

buildChart();
autoCompute();
</script>
</body>
</html>

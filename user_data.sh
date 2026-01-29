#!/bin/bash
# Update system and install httpd (Apache)
sudo yum update -y
sudo yum install -y httpd
# Start httpd service and enable it to start on boot
sudo systemctl start httpd
sudo systemctl enable httpd

# Fetch metadata using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AMI_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-id)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)
PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
HOSTNAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/hostname)

# Create a web page to display the metadata
sudo cat <<EOF > /var/www/html/index.html
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>FDM Tech Session · ElleHacks 2026</title>
<style>
:root{
  --bg:#c8f70a;
  --ink:#0a0a0a;
  --ink2:#222;
  --card:rgba(255,255,255,.16);
  --card-b:rgba(255,255,255,.38);
}
*{box-sizing:border-box} html,body{height:100%}
body{
  margin:0;background:var(--bg);color:var(--ink);
  font:16px/1.45 system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial;
  -webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale;overflow-x:hidden
}
header{position:relative;max-width:1100px;margin:24px auto 0;padding:24px clamp(16px,4vw,28px)}
.ribbon{
  display:inline-flex;gap:10px;align-items:center;padding:8px 12px;border-radius:999px;
  border:1px solid rgba(0,0,0,.18);background:rgba(255,255,255,.18);
  backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px)
}
.small{font-weight:800;letter-spacing:.4px;font-size:12px;text-transform:uppercase;white-space:nowrap}
.title{
  margin:14px 0 6px;font-size:clamp(34px,6vw,64px);font-weight:900;line-height:1.02;letter-spacing:-.02em;
  background:linear-gradient(90deg,#000,#333,#000);-webkit-background-clip:text;background-clip:text;color:transparent;
  text-shadow:0 1px 0 rgba(255,255,255,.2),0 8px 26px rgba(0,0,0,.15);animation:shine 4s ease-in-out infinite
}
@keyframes shine{50%{filter:drop-shadow(0 0 14px rgba(255,255,255,.35))}}
.underline{
  height:3px;border-radius:999px;background:linear-gradient(90deg,transparent,#000,transparent);
  background-size:200% 100%;animation:sweep 2.4s ease-in-out infinite;opacity:.55
}
@keyframes sweep{0%{background-position:200% 0}100%{background-position:-200% 0}}
.subtitle{margin:10px 0 0;font-size:clamp(16px,2.2vw,21px);color:var(--ink2)}

.bgfx{position:fixed;inset:0;pointer-events:none;z-index:0}
.bgfx::before,.bgfx::after{
  content:"";position:absolute;inset:-15%;filter:blur(40px);opacity:.4;mix-blend-mode:overlay
}
.bgfx::before{background:radial-gradient(40% 30% at 85% 12%,#fff6,transparent 60%)}
.bgfx::after{background:radial-gradient(45% 30% at 15% 100%,#fff5,transparent 65%);animation:float 16s ease-in-out infinite alternate}
@keyframes float{to{transform:translateY(3%) translateX(1%)}}

.stage{position:relative;z-index:1;max-width:1100px;margin:26px auto 80px;padding:0 clamp(16px,4vw,28px);
  display:grid;gap:22px;grid-template-columns:1.15fr .85fr}
@media (max-width:920px){.stage{grid-template-columns:1fr}}

.card{
  position:relative;padding:clamp(16px,3vw,22px);border-radius:18px;background:var(--card);border:1px solid var(--card-b);
  backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);box-shadow:0 12px 30px rgba(0,0,0,.18);transition:transform .2s ease,box-shadow .2s ease
}
.card:hover{box-shadow:0 16px 40px rgba(0,0,0,.22)}
.card h2{margin:0 0 10px;font-size:19px;letter-spacing:.2px}
.meta{display:grid;grid-template-columns:max-content 1fr;gap:10px 14px;font-size:15px}
.k{font-weight:800;color:#111}.v{font-weight:600;color:#202020;word-break:break-word}
.chip{
  display:inline-flex;align-items:center;gap:8px;padding:8px 12px;border-radius:12px;
  background:rgba(255,255,255,.22);border:1px solid rgba(255,255,255,.38);font-weight:700
}
.cta{margin-top:14px;display:flex;gap:10px;flex-wrap:wrap}
.btn{
  appearance:none;border:0;cursor:pointer;padding:10px 14px;border-radius:11px;
  font-weight:800;letter-spacing:.2px;text-decoration:none;display:inline-block
}
.primary{background:#000;color:#fff;box-shadow:0 10px 20px rgba(0,0,0,.22)}
.ghost{background:transparent;border:2px solid #000;color:#000}

.tilt{transform-style:preserve-3d}

footer{max-width:1100px;margin:0 auto 40px;padding:0 clamp(16px,4vw,28px);font-size:14px;color:#1a1a1a;
  display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap}
.muted{opacity:.85}

@media (prefers-reduced-motion:reduce){
  .title,.underline,.bgfx::after{animation:none!important}
}
</style>
</head>
<body>
<div class="bgfx" aria-hidden="true"></div>

<header>
  <div class="ribbon"><span class="small">ElleHacks 2026 • FDM Tech Session</span></div>
  <h1 class="title">Welcome to the FDM Tech Session in ElleHacks’s 2026</h1>
  <div class="underline"></div>
  <p class="subtitle">Hands‑on demos, cloud diagnostics, and live Q&amp;A — welcome!</p>
</header>

<main class="stage">
  <section class="card tilt">
    <h2>Session Details</h2>
    <div class="meta">
      <div class="k">Topic</div><div class="v">Deploy a Web Application on a Highly Available and Scalable AWS Environment</div>
      <div class="k">Reply</div><div class="v"><span class="chip">Reply coming from <strong>$HOSTNAME </strong></span></div>
      <div class="k">Public IP</div><div class="v"><strong>$PUBLIC_IP </strong></div>
      <div class="k">When</div><div class="v">2026 · Live</div>
      <div class="k">Where</div><div class="v">Main Workshop Stage</div>
    </div>

    <div class="cta">
      <!-- AWS Auto Scaling Docs (unchanged) -->
      <a class="btn primary" href="https://docs.aws.amazon.com/autoscaling/" 
         target="_blank" rel="noopener noreferrer">
        AWS Auto Scaling Docs
      </a>

      <!-- NEW: FDM Website button -->
      <a class="btn ghost" href="https://www.fdmgroup.com" 
         target="_blank" rel="noopener noreferrer">
        FDM Website
      </a>
    </div>
  </section>

  <aside class="card tilt">
    <h2>Quick Start</h2>
    <ul style="margin:0 0 10px 18px;line-height:1.55">
      <li>Confirm connectivity (hostname ✓, public IP ✓).</li>
      <li>Open the resource pack &amp; sample scripts.</li>
      <li>Ask a coach if you get stuck — we’ve got you.</li>
    </ul>
    <div class="chip">Live Support • On Site</div>
  </aside>
</main>



<script>
addEventListener('mousemove',e=>{
  const x=(e.clientX/innerWidth-.5)*6, y=(e.clientY/innerHeight-.5)*-6;
  document.querySelectorAll('.tilt')
    .forEach(el=>el.style.transform=`rotateX(${y}deg) rotateY(${x}deg)`)
},{passive:true});
</script>
</body>
</html>
EOF

# Permissions and restart
chown -R apache:apache /var/www/html || true
systemctl restart httpd || true

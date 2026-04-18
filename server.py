#!/usr/bin/env python3
"""
La Fosca PDF Generator — Servidor Flask
"""
from flask import Flask, request, send_file, render_template_string
import io, os, base64, tempfile

app = Flask(__name__)

HTML = """<!DOCTYPE html>
<html lang="ca">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="apple-mobile-web-app-capable" content="yes">
<title>La Fosca · Recomanacions</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;600&family=DM+Sans:wght@300;400;500&display=swap');
  :root {
    --terra: #C8956B; --terra-d: #A67550; --terra-l: #F5EBE0;
    --dark: #2C1810; --mid: #5C4035; --grey: #9A8880; --border: #E8D5C0;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'DM Sans', sans-serif; background: #FFFBF5; color: var(--dark); min-height: 100vh; }
  .hero {
    height: 200px;
    background: url('https://raw.githubusercontent.com/dframis-source/lafosca-pdf/main/static/cala_salguer.jpg') center/cover;
    position: relative;
  }
  .hero::after { content:''; position:absolute; inset:0; background:linear-gradient(to bottom,rgba(44,24,16,.1),rgba(44,24,16,.6)); }
  .hero-text { position:absolute; bottom:1.2rem; left:1.4rem; z-index:1; color:white; }
  .hero-text h1 { font-family:'Playfair Display',serif; font-size:1.6rem; }
  .hero-text p { font-size:.8rem; opacity:.85; letter-spacing:.06em; text-transform:uppercase; }
  .main { max-width:520px; margin:0 auto; padding:1.6rem 1.2rem 3rem; }
  .section-title { font-family:'Playfair Display',serif; font-size:1.05rem; color:var(--terra-d); margin-bottom:.9rem; padding-bottom:.4rem; border-bottom:1px solid var(--border); }
  .form-group { margin-bottom:1rem; }
  label { display:block; font-size:.75rem; font-weight:500; color:var(--grey); text-transform:uppercase; letter-spacing:.07em; margin-bottom:.35rem; }
  input, textarea, select {
    width:100%; padding:.7rem .9rem; border:1px solid var(--border); border-radius:8px;
    background:white; font-family:'DM Sans',sans-serif; font-size:.92rem; color:var(--dark);
    outline:none; -webkit-appearance:none; transition:border-color .2s;
  }
  input:focus, select:focus { border-color:var(--terra); box-shadow:0 0 0 3px rgba(200,149,107,.15); }
  .toggle-row {
    display:flex; align-items:center; justify-content:space-between;
    padding:.7rem .9rem; background:white; border:1px solid var(--border); border-radius:8px;
  }
  .toggle-label small { display:block; font-size:.72rem; color:var(--grey); margin-top:2px; }
  .toggle { position:relative; width:42px; height:22px; }
  .toggle input { opacity:0; width:0; height:0; }
  .slider { position:absolute; inset:0; background:#ddd; border-radius:22px; cursor:pointer; transition:background .2s; }
  .slider::before { content:''; position:absolute; height:16px; width:16px; left:3px; top:3px; background:white; border-radius:50%; transition:transform .2s; }
  .toggle input:checked + .slider { background:var(--terra); }
  .toggle input:checked + .slider::before { transform:translateX(20px); }
  .divider { height:1px; background:var(--border); margin:1.3rem 0; }
  .btn-generate {
    width:100%; padding:.95rem; background:var(--terra); color:white; border:none;
    border-radius:10px; font-family:'DM Sans',sans-serif; font-size:.95rem; font-weight:500;
    cursor:pointer; transition:background .2s;
  }
  .btn-generate:hover { background:var(--terra-d); }
  .btn-generate:disabled { background:#ccc; cursor:not-allowed; }
  .loading { display:none; text-align:center; padding:1.5rem; color:var(--grey); }
  .spinner { width:28px; height:28px; border:3px solid var(--border); border-top-color:var(--terra); border-radius:50%; animation:spin .8s linear infinite; margin:0 auto .6rem; }
  @keyframes spin { to { transform:rotate(360deg); } }
  .error { background:#fff0f0; border:1px solid #ffcccc; border-radius:8px; padding:.8rem 1rem; color:#c00; font-size:.85rem; margin-top:1rem; display:none; }
</style>
</head>
<body>
<div class="hero">
  <div class="hero-text">
    <h1>La Fosca</h1>
    <p>Generador de recomanacions · Palamós</p>
  </div>
</div>
<div class="main">
  <p class="section-title">Dades de l'estada</p>

  <div class="form-group">
    <label>Nom de la persona o família</label>
    <input type="text" id="nom" placeholder="ex: Família García · Rosa · Marc i Anna">
  </div>

  <div class="form-group">
    <label>Idioma</label>
    <select id="idioma">
      <option value="catala">Català</option>
      <option value="castella">Castellà</option>
      <option value="angles">Anglès</option>
      <option value="alemany">Alemany</option>
    </select>
  </div>

  <div class="form-group">
    <div class="toggle-row">
      <div class="toggle-label">
        Estiu (juliol – agost)
        <small>Activa per incloure Spar, Forn i Bus</small>
      </div>
      <label class="toggle">
        <input type="checkbox" id="estiu">
        <span class="slider"></span>
      </label>
    </div>
  </div>

  <div class="form-group">
    <label>Notes especials (opcional)</label>
    <textarea id="notes" rows="3" placeholder="Al·lèrgies, peticions, particularitats..."></textarea>
  </div>

  <div class="divider"></div>

  <button class="btn-generate" onclick="generate()">🌊 Generar PDF</button>

  <div class="loading" id="loading">
    <div class="spinner"></div>
    <p>Generant el document...</p>
  </div>

  <div class="error" id="error"></div>
</div>

<script>
async function generate() {
  const nom = document.getElementById('nom').value.trim();
  if (!nom) { alert('Si us plau, introdueix el nom.'); return; }

  document.querySelector('.btn-generate').disabled = true;
  document.getElementById('loading').style.display = 'block';
  document.getElementById('error').style.display = 'none';

  try {
    const r = await fetch('/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nom: nom,
        idioma: document.getElementById('idioma').value,
        estiu: document.getElementById('estiu').checked,
        notes: document.getElementById('notes').value.trim()
      })
    });

    if (!r.ok) {
      const err = await r.text();
      throw new Error(err);
    }

    const blob = await r.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `LaFosca_${nom.replace(/\s+/g,'_')}.pdf`;
    a.click();
    URL.revokeObjectURL(url);

  } catch(e) {
    document.getElementById('error').textContent = 'Error: ' + e.message;
    document.getElementById('error').style.display = 'block';
  } finally {
    document.querySelector('.btn-generate').disabled = false;
    document.getElementById('loading').style.display = 'none';
  }
}
</script>
</body>
</html>"""

@app.route('/')
def index():
    return render_template_string(HTML)

@app.route('/generate', methods=['POST'])
def generate():
    from pdf_generator import generate_pdf
    data = request.get_json()
    nom    = data.get('nom', 'Hostes')
    idioma = data.get('idioma', 'catala')
    estiu  = data.get('estiu', False)
    notes  = data.get('notes', '')

    try:
        pdf_bytes = generate_pdf(nom, idioma, estiu, notes)
        return send_file(
            io.BytesIO(pdf_bytes),
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f'LaFosca_{nom.replace(" ","_")}.pdf'
        )
    except Exception as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)

(function () {
  const canvas = document.getElementById('electric-bg');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  let w, h, nodes = [], sparks = [];
  const mouse = { x: -9999, y: -9999, active: false };

  const CONFIG = {
    nodeCount: 70,
    maxDist: 140,
    mouseRadius: 180,
    nodeColor: 'rgba(230, 209, 138, 0.9)',
    lineColor: 'rgba(230, 209, 138, ',
    arcColor: 'rgba(230, 209, 138, ',
    glowColor: '#e6d18a',
    nodeRadius: 0.85,
    nodePulse: 0.35,
    lineWidth: 0.6,
    lineAlpha: 0.35,
    shadowBlur: 10,
  };

  function updateConfigForViewport() {
    const mobile = window.matchMedia('(max-width: 600px)').matches;
    CONFIG.nodeRadius = mobile ? 0.6 : 0.85;
    CONFIG.nodePulse = mobile ? 0.22 : 0.35;
    CONFIG.nodeColor = 'rgba(230, 209, 138, ' + (mobile ? '0.8' : '0.9') + ')';
    CONFIG.maxDist = mobile ? 110 : 140;
    CONFIG.lineWidth = mobile ? 0.45 : 0.6;
    CONFIG.lineAlpha = mobile ? 0.3 : 0.35;
    CONFIG.shadowBlur = mobile ? 6 : 10;
  }

  function resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    w = window.innerWidth;
    h = window.innerHeight;
    canvas.width = Math.floor(w * dpr);
    canvas.height = Math.floor(h * dpr);
    canvas.style.width = w + 'px';
    canvas.style.height = h + 'px';
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    updateConfigForViewport();
  }
  window.addEventListener('resize', resize);
  resize();

  for (let i = 0; i < CONFIG.nodeCount; i++) {
    nodes.push({
      x: Math.random() * w,
      y: Math.random() * h,
      vx: (Math.random() - 0.5) * 0.35,
      vy: (Math.random() - 0.5) * 0.35,
      pulse: Math.random() * Math.PI * 2,
    });
  }

  window.addEventListener('mousemove', e => {
    mouse.x = e.clientX; mouse.y = e.clientY; mouse.active = true;
  });
  window.addEventListener('mouseleave', () => { mouse.active = false; mouse.x = -9999; mouse.y = -9999; });
  window.addEventListener('click', e => {
    for (let i = 0; i < 8; i++) {
      sparks.push({
        x: e.clientX, y: e.clientY,
        vx: (Math.random() - 0.5) * 6,
        vy: (Math.random() - 0.5) * 6,
        life: 1,
      });
    }
  });

  window.addEventListener('touchmove', e => {
    if (e.touches.length > 0) {
      mouse.x = e.touches[0].clientX;
      mouse.y = e.touches[0].clientY;
      mouse.active = true;
    }
  }, { passive: true });
  window.addEventListener('touchstart', e => {
    if (e.touches.length > 0) {
      mouse.x = e.touches[0].clientX;
      mouse.y = e.touches[0].clientY;
      mouse.active = true;
      for (let i = 0; i < 6; i++) {
        sparks.push({
          x: mouse.x, y: mouse.y,
          vx: (Math.random() - 0.5) * 5,
          vy: (Math.random() - 0.5) * 5,
          life: 1,
        });
      }
    }
  }, { passive: true });
  window.addEventListener('touchend', () => {
    setTimeout(() => { mouse.active = false; }, 1500);
  });

  function drawLightning(x1, y1, x2, y2, alpha) {
    const segments = 5;
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    for (let i = 1; i < segments; i++) {
      const t = i / segments;
      const mx = x1 + (x2 - x1) * t + (Math.random() - 0.5) * 8;
      const my = y1 + (y2 - y1) * t + (Math.random() - 0.5) * 8;
      ctx.lineTo(mx, my);
    }
    ctx.lineTo(x2, y2);
    ctx.strokeStyle = CONFIG.arcColor + alpha + ')';
    ctx.lineWidth = 1.2;
    ctx.shadowBlur = 8;
    ctx.shadowColor = CONFIG.glowColor;
    ctx.stroke();
    ctx.shadowBlur = 0;
  }

  function animate() {
    ctx.clearRect(0, 0, w, h);

    for (const n of nodes) {
      n.x += n.vx; n.y += n.vy;
      if (n.x < 0 || n.x > w) n.vx *= -1;
      if (n.y < 0 || n.y > h) n.vy *= -1;

      if (mouse.active) {
        const dx = mouse.x - n.x, dy = mouse.y - n.y;
        const d = Math.hypot(dx, dy);
        if (d < CONFIG.mouseRadius) {
          const force = (CONFIG.mouseRadius - d) / CONFIG.mouseRadius * 0.4;
          n.x -= (dx / d) * force;
          n.y -= (dy / d) * force;
        }
      }

      n.pulse += 0.04;
    }

    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i], b = nodes[j];
        const d = Math.hypot(a.x - b.x, a.y - b.y);
        if (d < CONFIG.maxDist) {
          const alpha = (1 - d / CONFIG.maxDist) * CONFIG.lineAlpha;
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.strokeStyle = CONFIG.lineColor + alpha + ')';
          ctx.lineWidth = CONFIG.lineWidth;
          ctx.stroke();
        }
      }
    }

    if (mouse.active) {
      for (const n of nodes) {
        const d = Math.hypot(mouse.x - n.x, mouse.y - n.y);
        if (d < CONFIG.mouseRadius) {
          const alpha = (1 - d / CONFIG.mouseRadius) * 0.9;
          drawLightning(mouse.x, mouse.y, n.x, n.y, alpha);
        }
      }
    }

    for (const n of nodes) {
      const r = CONFIG.nodeRadius + Math.sin(n.pulse) * CONFIG.nodePulse;
      ctx.beginPath();
      ctx.arc(n.x, n.y, r, 0, Math.PI * 2);
      ctx.fillStyle = CONFIG.nodeColor;
      ctx.shadowBlur = CONFIG.shadowBlur;
      ctx.shadowColor = CONFIG.glowColor;
      ctx.fill();
      ctx.shadowBlur = 0;
    }

    sparks = sparks.filter(s => s.life > 0);
    const sparkRadius = window.matchMedia('(max-width: 600px)').matches ? 1.8 : 2.5;
    for (const s of sparks) {
      s.x += s.vx; s.y += s.vy; s.life -= 0.03;
      ctx.beginPath();
      ctx.arc(s.x, s.y, sparkRadius, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(230, 209, 138, ' + s.life + ')';
      ctx.shadowBlur = 14;
      ctx.shadowColor = CONFIG.glowColor;
      ctx.fill();
      ctx.shadowBlur = 0;
    }

    requestAnimationFrame(animate);
  }
  animate();
})();

document.querySelectorAll('.check-item input[type="checkbox"]').forEach(input => {
  input.addEventListener('change', () => {
    const item = input.closest('.check-item');
    item.classList.toggle('checked', input.checked);
    const otroInput = item.querySelector('.otro-inline-input');
    if (otroInput) {
      if (input.checked) {
        setTimeout(() => otroInput.focus(), 80);
      } else {
        otroInput.value = '';
      }
    }
  });
});

document.querySelectorAll('.otro-inline-input').forEach(input => {
  ['click', 'mousedown', 'touchstart'].forEach(evt => {
    input.addEventListener(evt, e => e.stopPropagation());
  });
});

document.querySelectorAll('.radio-item input[type="radio"]').forEach(input => {
  input.addEventListener('change', () => {
    const name = input.name;
    document.querySelectorAll('input[type="radio"][name="' + name + '"]').forEach(r => {
      r.closest('.radio-item').classList.toggle('selected', r.checked);
    });
  });
});

const BUSINESS_WHATSAPP = '59894492019';

function buildCotizacionMessage(form) {
  const servicios = [...form.querySelectorAll('input[name="servicio"]:checked')].map(cb => {
    if (cb.value === 'Otro' && form.otro_trabajo?.value.trim()) {
      return 'Otro: ' + form.otro_trabajo.value.trim();
    }
    return cb.value;
  });
  const contacto = form.querySelector('input[name="contacto"]:checked')?.value || 'No indicó';
  const lines = [
    '*Nueva solicitud de cotización*',
    'Soluciones Eléctricas EP',
    '',
    '*Nombre:* ' + form.nombre.value.trim(),
    '*Teléfono:* ' + form.telefono.value.trim(),
  ];
  const email = form.email?.value.trim();
  if (email) lines.push('*Email:* ' + email);
  lines.push(
    '*Barrio:* ' + form.barrio.value.trim(),
    '*Trabajos:* ' + servicios.join(', '),
  );
  const descripcion = form.descripcion?.value.trim();
  if (descripcion) lines.push('*Detalle:* ' + descripcion);
  lines.push('*Contacto preferido:* ' + contacto);
  return lines.join('\n');
}

function openWhatsAppWithMessage(text) {
  const url = 'https://wa.me/' + BUSINESS_WHATSAPP + '?text=' + encodeURIComponent(text);
  const win = window.open(url, '_blank', 'noopener,noreferrer');
  if (!win) window.location.href = url;
}

const cotizacionForm = document.getElementById('form');
if (cotizacionForm) {
  cotizacionForm.addEventListener('submit', function (e) {
    e.preventDefault();
    const nombre = this.nombre.value.trim();
    const telefono = this.telefono.value.trim();
    const barrio = this.barrio.value.trim();
    const servicios = [...document.querySelectorAll('input[name="servicio"]:checked')];
    const otroChecked = document.querySelector('input[name="servicio"][value="Otro"]')?.checked;
    const otroTrabajo = (this.otro_trabajo?.value || '').trim();
    if (!nombre || !telefono || !barrio || servicios.length === 0 || (otroChecked && !otroTrabajo)) {
      const missing = [];
      if (!nombre) missing.push('nombre');
      if (!telefono) missing.push('teléfono');
      if (!barrio) missing.push('barrio');
      if (servicios.length === 0) missing.push('tipo de trabajo');
      if (otroChecked && !otroTrabajo) missing.push('especificación de otro trabajo');
      alert('Por favor completá: ' + missing.join(', ') + '.');
      return;
    }
    openWhatsAppWithMessage(buildCotizacionMessage(this));
    document.getElementById('form').style.display = 'none';
    document.getElementById('success').style.display = 'block';
  });
}

(function () {
  const grid = document.getElementById('galeriaGrid');
  const empty = document.getElementById('galeriaEmpty');
  if (!grid) return;

  const candidates = ['fotos-web/inicio.jpg'];
  for (let i = 1; i <= 20; i++) {
    const n = String(i).padStart(2, '0');
    candidates.push(`fotos-web/trabajo-${n}.jpg`);
    candidates.push(`fotos-web/trabajo-${n}.jpeg`);
    candidates.push(`fotos-web/trabajo-${n}.png`);
  }

  let loadedCount = 0;
  let checkedCount = 0;

  const finalize = () => {
    if (checkedCount !== candidates.length) return;
    if (loadedCount === 0 && empty) empty.hidden = false;
  };

  candidates.forEach((src, idx) => {
    const img = new Image();
    img.loading = 'lazy';
    img.src = src;
    img.alt = `Trabajo ${idx + 1}`;

    img.onload = () => {
      const card = document.createElement('figure');
      card.className = 'galeria-card';
      card.appendChild(img);
      grid.appendChild(card);
      loadedCount += 1;
      checkedCount += 1;
      finalize();
    };

    img.onerror = () => {
      checkedCount += 1;
      finalize();
    };
  });
})();

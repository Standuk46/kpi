document.addEventListener('DOMContentLoaded', () => {
    /* ====== БУРГЕР-МЕНЮ КАТАЛОГУ ====== */
    const catalogToggle = document.getElementById('catalogToggle');
    const catalogDropdown = document.getElementById('catalogDropdown');

    if (catalogToggle && catalogDropdown) {
        catalogToggle.addEventListener('click', (e) => {
            e.stopPropagation();
            catalogDropdown.classList.toggle('open');
        });

        // Закриття при кліку поза меню
        document.addEventListener('click', (e) => {
            if (!catalogDropdown.contains(e.target) && e.target !== catalogToggle) {
                catalogDropdown.classList.remove('open');
            }
        });

        // Закриття по Esc
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                catalogDropdown.classList.remove('open');
            }
        });
    }

    /* ====== Горизонтальні каруселі книжок (секції products) ====== */
    document.querySelectorAll('.products').forEach(section => {
        const track = section.querySelector('.product-carousel');
        const prevBtn = section.querySelector('.prev-btn');
        const nextBtn = section.querySelector('.next-btn');

        if (!track || !prevBtn || !nextBtn) return;

        const scrollAmount = 260;

        prevBtn.addEventListener('click', () => {
            track.scrollBy({ left: -scrollAmount, behavior: 'smooth' });
        });

        nextBtn.addEventListener('click', () => {
            track.scrollBy({ left: scrollAmount, behavior: 'smooth' });
        });
    });
});

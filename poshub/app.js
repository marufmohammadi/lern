// ===== SIDEBAR TOGGLE =====
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const wrapper = document.querySelector('.main-wrapper');
  sidebar.classList.toggle('collapsed');
  wrapper.classList.toggle('collapsed');
}

// ===== ACCORDION NAV GROUP =====
function toggleGroup(header) {
  const sub = header.nextElementSibling;
  const isOpen = sub.classList.contains('open');

  // Close all open groups
  document.querySelectorAll('.nav-sub.open').forEach(s => {
    s.classList.remove('open');
    s.previousElementSibling.classList.remove('open');
  });

  // Open clicked group if it was closed
  if (!isOpen) {
    sub.classList.add('open');
    header.classList.add('open');
  }
}

// ===== NAV DASHBOARD ITEM =====
document.querySelector('.nav-item[data-page="dashboard"]')?.addEventListener('click', e => {
  e.preventDefault();
  document.querySelectorAll('.nav-sub-item').forEach(i => i.classList.remove('active'));
  document.querySelector('.nav-item[data-page="dashboard"]').classList.add('active');
});

// ===== NAV SUB-ITEM ACTIVE STATE =====
document.querySelectorAll('.nav-sub-item').forEach(item => {
  item.addEventListener('click', e => {
    e.preventDefault();
    document.querySelectorAll('.nav-sub-item').forEach(i => i.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    item.classList.add('active');
  });
});

// ===== TAB SWITCHING =====
document.querySelectorAll('.card-tabs .tab').forEach(tab => {
  tab.addEventListener('click', () => {
    tab.closest('.card-tabs').querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
  });
});
document.querySelectorAll('.card-actions .btn-outline').forEach(btn => {
  btn.addEventListener('click', () => {
    btn.closest('.card-actions').querySelectorAll('.btn-outline').forEach(b => b.classList.remove('active-btn'));
    btn.classList.add('active-btn');
  });
});

// ===== CHART: Sales Limit Chart =====
const salesCtx = document.getElementById('salesLimitChart').getContext('2d');
const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

new Chart(salesCtx, {
  type: 'line',
  data: {
    labels: months,
    datasets: [
      {
        label: 'Sales Amount',
        data: [0, 250, 180, 420, 310, 500, 280, 650, 400, 720, 480, 1427],
        borderColor: '#2d8c4e',
        backgroundColor: 'rgba(45,140,78,0.08)',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        fill: true,
      },
      {
        label: 'Purchase Amount',
        data: [0, 180, 140, 300, 250, 400, 220, 500, 350, 600, 400, 1007],
        borderColor: '#f59e0b',
        backgroundColor: 'rgba(245,158,11,0.07)',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        fill: true,
      },
      {
        label: 'Profit',
        data: [0, 70, 40, 120, 60, 100, 60, 150, 50, 120, 80, 420],
        borderColor: '#f97316',
        backgroundColor: 'transparent',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        borderDash: [],
      },
      {
        label: 'Expense',
        data: [0, 10, 5, 20, 15, 30, 10, 25, 20, 40, 15, 1],
        borderColor: '#ef4444',
        backgroundColor: 'transparent',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        borderDash: [4,3],
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        mode: 'index',
        intersect: false,
        backgroundColor: '#1e293b',
        titleFont: { size: 12 },
        bodyFont: { size: 11 },
        padding: 10,
        cornerRadius: 8,
      }
    },
    scales: {
      x: {
        grid: { color: 'rgba(0,0,0,0.04)' },
        ticks: { font: { size: 10 }, color: '#94a3b8' }
      },
      y: {
        grid: { color: 'rgba(0,0,0,0.04)' },
        ticks: { font: { size: 10 }, color: '#94a3b8' },
        beginAtZero: true
      }
    },
    interaction: { mode: 'nearest', axis: 'x', intersect: false }
  }
});

// ===== CHART: Payment Method Chart =====
const payCtx = document.getElementById('paymentChart').getContext('2d');

new Chart(payCtx, {
  type: 'line',
  data: {
    labels: months,
    datasets: [
      {
        label: 'Cash',
        data: [0, 150, 100, 250, 200, 300, 180, 400, 250, 500, 300, 900],
        borderColor: '#2d8c4e',
        backgroundColor: 'rgba(45,140,78,0.07)',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        fill: true,
      },
      {
        label: 'Card',
        data: [0, 60, 50, 100, 80, 120, 70, 150, 100, 150, 120, 300],
        borderColor: '#f59e0b',
        backgroundColor: 'transparent',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
      },
      {
        label: 'Mobile Banking',
        data: [0, 30, 20, 50, 20, 60, 20, 80, 40, 60, 50, 150],
        borderColor: '#f97316',
        backgroundColor: 'transparent',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
      },
      {
        label: 'Bank Transfer',
        data: [0, 10, 5, 15, 5, 15, 8, 15, 5, 8, 7, 50],
        borderColor: '#ef4444',
        backgroundColor: 'transparent',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        borderDash: [4,3],
      },
      {
        label: 'Credit',
        data: [0, 0, 5, 5, 5, 5, 2, 5, 5, 2, 3, 27],
        borderColor: '#3b82f6',
        backgroundColor: 'transparent',
        tension: 0.4,
        pointRadius: 3,
        pointHoverRadius: 5,
        borderDash: [4,3],
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        mode: 'index',
        intersect: false,
        backgroundColor: '#1e293b',
        titleFont: { size: 12 },
        bodyFont: { size: 11 },
        padding: 10,
        cornerRadius: 8,
      }
    },
    scales: {
      x: {
        grid: { color: 'rgba(0,0,0,0.04)' },
        ticks: { font: { size: 10 }, color: '#94a3b8' }
      },
      y: {
        grid: { color: 'rgba(0,0,0,0.04)' },
        ticks: { font: { size: 10 }, color: '#94a3b8' },
        beginAtZero: true
      }
    },
    interaction: { mode: 'nearest', axis: 'x', intersect: false }
  }
});

// ===== ANIMATED COUNTER FOR STAT VALUES =====
function animateCount(el, target, prefix = '৳ ', decimals = 2) {
  let start = 0;
  const duration = 1200;
  const step = (timestamp) => {
    if (!start) start = timestamp;
    const progress = Math.min((timestamp - start) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    el.textContent = prefix + (eased * target).toFixed(decimals);
    if (progress < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

document.querySelectorAll('.stat-value').forEach(el => {
  const raw = el.textContent.replace(/[^\d.]/g, '');
  const val = parseFloat(raw);
  if (!isNaN(val)) animateCount(el, val);
});

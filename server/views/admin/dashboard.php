<?php
/** @var array $stats */
/** @var array $recentInquiries */
/** @var array $recentReservations */
/** @var array $inquiriesPerDay */

$statCards = [
    ['label' => 'Total Properties', 'value' => $stats['properties_total'], 'accent' => 'indigo',
     'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 11l9-8 9 8"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/></svg>'],
    ['label' => 'Published', 'value' => $stats['properties_published'], 'accent' => 'emerald',
     'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M8.5 12.5l2.5 2.5 4.5-5"/></svg>'],
    ['label' => 'Users', 'value' => $stats['users'], 'accent' => 'gold',
     'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="8" r="3.5"/><path d="M5 20c.9-3.4 3.7-5.2 7-5.2s6.1 1.8 7 5.2"/></svg>'],
    ['label' => 'New Inquiries', 'value' => $stats['new_inquiries'], 'accent' => 'indigo',
     'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 5h16a1 1 0 011 1v10a1 1 0 01-1 1H9l-5 4V6a1 1 0 011-1z"/></svg>'],
    ['label' => 'Pending Reservations', 'value' => $stats['pending_reservations'], 'accent' => 'gold',
     'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9.5h18M8 3v4M16 3v4"/></svg>'],
    ['label' => 'Total Views', 'value' => $stats['total_views'], 'accent' => 'emerald',
     'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M2 12s3.5-6.5 10-6.5S22 12 22 12s-3.5 6.5-10 6.5S2 12 2 12z"/><circle cx="12" cy="12" r="2.8"/></svg>'],
];

$maxCount = 1;
foreach ($inquiriesPerDay as $d) {
    $maxCount = max($maxCount, $d['count']);
}
?>
<div class="stat-grid">
  <?php foreach ($statCards as $card): ?>
  <div class="card stat-card accent-<?= e($card['accent']) ?>">
    <span class="stat-icon"><?= $card['icon'] ?></span>
    <div>
      <div class="stat-value"><?= e(number_format((int)$card['value'])) ?></div>
      <div class="stat-label"><?= e($card['label']) ?></div>
    </div>
  </div>
  <?php endforeach; ?>
</div>

<div class="card">
  <div class="card-head"><h2>Inquiries — last 7 days</h2></div>
  <div class="chart">
    <?php
      $w = 700; $h = 200; $pad = 28;
      $n = count($inquiriesPerDay);
      $barAreaW = ($w - $pad * 2) / max(1, $n);
      $barW = $barAreaW * 0.55;
    ?>
    <svg viewBox="0 0 <?= $w ?> <?= $h + 30 ?>" class="bar-chart" role="img" aria-label="Inquiries per day">
      <?php for ($g = 0; $g <= 4; $g++): $y = $h - ($h - $pad) * $g / 4; ?>
      <line x1="<?= $pad ?>" y1="<?= $y ?>" x2="<?= $w - $pad ?>" y2="<?= $y ?>" class="grid-line"/>
      <?php endfor; ?>
      <?php foreach ($inquiriesPerDay as $i => $d):
        $barH = (int)round(($h - $pad) * $d['count'] / $maxCount);
        $x = $pad + $i * $barAreaW + ($barAreaW - $barW) / 2;
        $y = $h - $barH;
      ?>
      <rect x="<?= $x ?>" y="<?= $y ?>" width="<?= $barW ?>" height="<?= max(2, $barH) ?>" rx="4" class="bar"/>
      <text x="<?= $x + $barW / 2 ?>" y="<?= $y - 6 ?>" text-anchor="middle" class="bar-value"><?= e($d['count']) ?></text>
      <text x="<?= $x + $barW / 2 ?>" y="<?= $h + 18 ?>" text-anchor="middle" class="bar-label"><?= e(date('n/j', strtotime($d['day']))) ?></text>
      <?php endforeach; ?>
    </svg>
  </div>
</div>

<div class="two-col">
  <div class="card">
    <div class="card-head">
      <h2>Recent Inquiries</h2>
      <a class="link" href="/admin/inquiries">View all →</a>
    </div>
    <table class="table">
      <thead><tr><th>Name</th><th>Property</th><th>Status</th><th>Date</th></tr></thead>
      <tbody>
        <?php if ($recentInquiries === []): ?>
        <tr><td colspan="4" class="empty">No inquiries yet.</td></tr>
        <?php endif; ?>
        <?php foreach ($recentInquiries as $row): ?>
        <tr>
          <td><?= e($row['name']) ?></td>
          <td class="truncate"><?= e($row['property_title']) ?></td>
          <td><span class="badge badge-<?= e($row['status']) ?>"><?= e(str_replace('_', ' ', $row['status'])) ?></span></td>
          <td class="muted"><?= e(date('n/j H:i', strtotime((string)$row['created_at']))) ?></td>
        </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
  <div class="card">
    <div class="card-head">
      <h2>Recent Reservations</h2>
      <a class="link" href="/admin/reservations">View all →</a>
    </div>
    <table class="table">
      <thead><tr><th>Name</th><th>Property</th><th>Visit</th><th>Status</th></tr></thead>
      <tbody>
        <?php if ($recentReservations === []): ?>
        <tr><td colspan="4" class="empty">No reservations yet.</td></tr>
        <?php endif; ?>
        <?php foreach ($recentReservations as $row): ?>
        <tr>
          <td><?= e($row['name']) ?></td>
          <td class="truncate"><?= e($row['property_title']) ?></td>
          <td class="muted"><?= e($row['preferred_date']) ?> <?= e($row['preferred_time']) ?></td>
          <td><span class="badge badge-<?= e($row['status']) ?>"><?= e($row['status']) ?></span></td>
        </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</div>

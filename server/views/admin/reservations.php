<?php

use App\Core\Csrf;
use App\Models\Reservation;

/** @var array $reservations */
?>
<div class="card">
  <div class="card-head"><h2>Viewing Reservations <span class="muted">(<?= e(count($reservations)) ?>)</span></h2></div>
  <div class="table-wrap">
  <table class="table">
    <thead>
      <tr><th>#</th><th>Visitor</th><th>Property</th><th>Preferred</th><th>Message</th><th>Status</th><th class="ta-r">Actions</th></tr>
    </thead>
    <tbody>
      <?php if ($reservations === []): ?>
      <tr><td colspan="7" class="empty">No reservations yet.</td></tr>
      <?php endif; ?>
      <?php foreach ($reservations as $row): $id = (int)$row['id']; ?>
      <tr>
        <td class="muted"><?= e($id) ?></td>
        <td>
          <strong><?= e($row['name']) ?></strong>
          <div class="muted small"><?= e($row['email']) ?></div>
          <?php if (!empty($row['phone'])): ?><div class="muted small"><?= e($row['phone']) ?></div><?php endif; ?>
        </td>
        <td class="truncate">
          <a class="link" href="/admin/properties/<?= e((int)$row['property_id']) ?>/edit"><?= e($row['property_title']) ?></a>
        </td>
        <td class="nowrap"><strong><?= e($row['preferred_date']) ?></strong> <span class="muted"><?= e($row['preferred_time']) ?></span></td>
        <td class="message-cell">
          <?php if (!empty($row['message'])): ?>
          <details>
            <summary><?= e(mb_strimwidth((string)$row['message'], 0, 40, '…')) ?></summary>
            <p><?= nl2br(e($row['message'])) ?></p>
          </details>
          <?php else: ?><span class="muted">—</span><?php endif; ?>
        </td>
        <td>
          <form method="post" action="/admin/reservations/<?= e($id) ?>/status" class="inline-form">
            <?= Csrf::field() ?>
            <select name="status" class="status-select status-<?= e($row['status']) ?>" data-autosubmit>
              <?php foreach (Reservation::STATUSES as $status): ?>
              <option value="<?= e($status) ?>" <?= $row['status'] === $status ? 'selected' : '' ?>><?= e($status) ?></option>
              <?php endforeach; ?>
            </select>
          </form>
        </td>
        <td class="ta-r">
          <form method="post" action="/admin/reservations/<?= e($id) ?>/delete" class="inline-form" data-confirm="Delete this reservation?">
            <?= Csrf::field() ?>
            <button type="submit" class="btn btn-danger btn-sm">Delete</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
  </div>
</div>

<?php

use App\Core\Csrf;

/** @var array $inquiries */
?>
<div class="card">
  <div class="card-head"><h2>Inquiries <span class="muted">(<?= e(count($inquiries)) ?>)</span></h2></div>
  <div class="table-wrap">
  <table class="table">
    <thead>
      <tr><th>#</th><th>From</th><th>Property</th><th>Message</th><th>Status</th><th>Received</th><th class="ta-r">Actions</th></tr>
    </thead>
    <tbody>
      <?php if ($inquiries === []): ?>
      <tr><td colspan="7" class="empty">No inquiries yet.</td></tr>
      <?php endif; ?>
      <?php foreach ($inquiries as $row): $id = (int)$row['id']; ?>
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
        <td class="message-cell">
          <details>
            <summary><?= e(mb_strimwidth((string)$row['message'], 0, 60, '…')) ?></summary>
            <p><?= nl2br(e($row['message'])) ?></p>
          </details>
        </td>
        <td>
          <form method="post" action="/admin/inquiries/<?= e($id) ?>/status" class="inline-form">
            <?= Csrf::field() ?>
            <select name="status" class="status-select status-<?= e($row['status']) ?>" data-autosubmit>
              <?php foreach (['new', 'in_progress', 'closed'] as $status): ?>
              <option value="<?= e($status) ?>" <?= $row['status'] === $status ? 'selected' : '' ?>><?= e(str_replace('_', ' ', $status)) ?></option>
              <?php endforeach; ?>
            </select>
          </form>
        </td>
        <td class="muted nowrap"><?= e(date('Y/n/j H:i', strtotime((string)$row['created_at']))) ?></td>
        <td class="ta-r">
          <form method="post" action="/admin/inquiries/<?= e($id) ?>/delete" class="inline-form" data-confirm="Delete this inquiry?">
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

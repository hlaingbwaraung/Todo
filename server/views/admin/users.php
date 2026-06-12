<?php

use App\Core\Csrf;

/** @var array $users */
/** @var array $admin */
?>
<div class="card">
  <div class="card-head"><h2>Users <span class="muted">(<?= e(count($users)) ?>)</span></h2></div>
  <div class="table-wrap">
  <table class="table">
    <thead>
      <tr><th>#</th><th>Name</th><th>Email</th><th>Phone</th><th>Role</th><th>Joined</th><th class="ta-r">Actions</th></tr>
    </thead>
    <tbody>
      <?php foreach ($users as $row): $id = (int)$row['id']; $isSelf = $id === (int)$admin['id']; ?>
      <tr>
        <td class="muted"><?= e($id) ?></td>
        <td><strong><?= e($row['name']) ?></strong><?= $isSelf ? ' <span class="badge badge-self">you</span>' : '' ?></td>
        <td><?= e($row['email']) ?></td>
        <td class="muted"><?= e($row['phone'] ?? '—') ?></td>
        <td>
          <?php if ($isSelf): ?>
          <span class="badge badge-admin">admin</span>
          <?php else: ?>
          <form method="post" action="/admin/users/<?= e($id) ?>/role" class="inline-form">
            <?= Csrf::field() ?>
            <input type="hidden" name="role" value="<?= e($row['role'] === 'admin' ? 'user' : 'admin') ?>">
            <button type="submit" class="badge-btn badge badge-<?= e($row['role']) ?>"
              title="Switch to <?= e($row['role'] === 'admin' ? 'user' : 'admin') ?>">
              <?= e($row['role']) ?> ⇄
            </button>
          </form>
          <?php endif; ?>
        </td>
        <td class="muted nowrap"><?= e(date('Y/n/j', strtotime((string)$row['created_at']))) ?></td>
        <td class="ta-r">
          <?php if (!$isSelf): ?>
          <form method="post" action="/admin/users/<?= e($id) ?>/delete" class="inline-form" data-confirm="Delete this user?">
            <?= Csrf::field() ?>
            <button type="submit" class="btn btn-danger btn-sm">Delete</button>
          </form>
          <?php else: ?>
          <span class="muted small">—</span>
          <?php endif; ?>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
  </div>
</div>

<?php

use App\Core\Csrf;

/** @var array $categories */
/** @var ?string $error */
?>
<?php if (!empty($error)): ?>
<div class="alert alert-error"><?= e($error) ?></div>
<?php endif; ?>

<div class="two-col two-col-wide">
  <div class="card">
    <div class="card-head"><h2>Categories <span class="muted">(<?= e(count($categories)) ?>)</span></h2></div>
    <div class="table-wrap">
    <table class="table">
      <thead><tr><th>#</th><th>Name</th><th>名称</th><th>Slug</th><th>Properties</th><th class="ta-r">Actions</th></tr></thead>
      <tbody>
        <?php foreach ($categories as $cat): $id = (int)$cat['id']; $count = (int)$cat['property_count']; ?>
        <tr>
          <td class="muted"><?= e($id) ?></td>
          <td colspan="3">
            <form method="post" action="/admin/categories/<?= e($id) ?>" class="inline-form cat-edit-form">
              <?= Csrf::field() ?>
              <input type="text" name="name" value="<?= e($cat['name']) ?>" required>
              <input type="text" name="name_ja" value="<?= e($cat['name_ja']) ?>" required>
              <input type="text" name="slug" value="<?= e($cat['slug']) ?>" pattern="[a-z0-9\-]+" required>
              <button type="submit" class="btn btn-secondary btn-sm">Save</button>
            </form>
          </td>
          <td><span class="badge badge-count"><?= e($count) ?></span></td>
          <td class="ta-r">
            <?php if ($count === 0): ?>
            <form method="post" action="/admin/categories/<?= e($id) ?>/delete" class="inline-form" data-confirm="Delete this category?">
              <?= Csrf::field() ?>
              <button type="submit" class="btn btn-danger btn-sm">Delete</button>
            </form>
            <?php else: ?>
            <span class="muted small" title="Has properties — cannot delete">locked</span>
            <?php endif; ?>
          </td>
        </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
    </div>
  </div>

  <div class="card">
    <div class="card-head"><h2>Add category</h2></div>
    <form method="post" action="/admin/categories" class="stack-form">
      <?= Csrf::field() ?>
      <label class="field">
        <span class="field-label">Name (EN)</span>
        <input type="text" name="name" required placeholder="Apartment">
      </label>
      <label class="field">
        <span class="field-label">Name (日本語)</span>
        <input type="text" name="name_ja" required placeholder="マンション">
      </label>
      <label class="field">
        <span class="field-label">Slug</span>
        <input type="text" name="slug" required pattern="[a-z0-9\-]+" placeholder="apartment">
      </label>
      <button type="submit" class="btn btn-primary btn-block">Add category</button>
    </form>
  </div>
</div>

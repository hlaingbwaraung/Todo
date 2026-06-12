<?php

use App\Core\Csrf;

/** @var array $rows */
/** @var array $meta */
/** @var array $thumbs */
/** @var array $filters */
/** @var array $categories */

function yen(int $v): string
{
    return '¥' . number_format($v);
}
?>
<div class="card">
  <div class="card-head">
    <h2>Properties <span class="muted">(<?= e($meta['total']) ?>)</span></h2>
    <a href="/admin/properties/create" class="btn btn-primary">+ New Property</a>
  </div>

  <form method="get" action="/admin/properties" class="filter-bar">
    <input type="search" name="q" placeholder="Search title, address, station…" value="<?= e($filters['q']) ?>">
    <select name="status">
      <option value="">All statuses</option>
      <option value="published" <?= $filters['status'] === 'published' ? 'selected' : '' ?>>Published</option>
      <option value="draft" <?= $filters['status'] === 'draft' ? 'selected' : '' ?>>Draft</option>
    </select>
    <select name="type">
      <option value="">Rent &amp; Buy</option>
      <option value="rent" <?= $filters['transaction_type'] === 'rent' ? 'selected' : '' ?>>Rent</option>
      <option value="buy" <?= $filters['transaction_type'] === 'buy' ? 'selected' : '' ?>>Buy</option>
    </select>
    <select name="category">
      <option value="">All categories</option>
      <?php foreach ($categories as $cat): ?>
      <option value="<?= e($cat['id']) ?>" <?= (string)$filters['category'] === (string)$cat['id'] ? 'selected' : '' ?>>
        <?= e($cat['name']) ?> / <?= e($cat['name_ja']) ?>
      </option>
      <?php endforeach; ?>
    </select>
    <button type="submit" class="btn btn-secondary">Filter</button>
  </form>

  <div class="table-wrap">
  <table class="table">
    <thead>
      <tr>
        <th></th><th>Property</th><th>Type</th><th>Price</th><th>Layout</th>
        <th>Status</th><th>Featured</th><th>Views</th><th class="ta-r">Actions</th>
      </tr>
    </thead>
    <tbody>
      <?php if ($rows === []): ?>
      <tr><td colspan="9" class="empty">No properties found.</td></tr>
      <?php endif; ?>
      <?php foreach ($rows as $row): $id = (int)$row['id']; ?>
      <tr>
        <td>
          <?php if (!empty($thumbs[$id])): ?>
          <img class="thumb" src="<?= e($thumbs[$id]) ?>" alt="" loading="lazy">
          <?php else: ?>
          <span class="thumb thumb-empty"></span>
          <?php endif; ?>
        </td>
        <td>
          <a class="row-title" href="/admin/properties/<?= e($id) ?>/edit"><?= e($row['title']) ?></a>
          <div class="muted small"><?= e($row['title_ja']) ?></div>
          <div class="muted small"><?= e($row['city']) ?> · <?= e($row['c_name'] ?? '—') ?></div>
        </td>
        <td><span class="badge badge-<?= e($row['transaction_type']) ?>"><?= e($row['transaction_type']) ?></span></td>
        <td class="nowrap"><?= e(yen((int)$row['price'])) ?><?= $row['transaction_type'] === 'rent' ? '<span class="muted small">/mo</span>' : '' ?></td>
        <td><?= e($row['layout']) ?></td>
        <td>
          <form method="post" action="/admin/properties/<?= e($id) ?>/toggle-status" class="inline-form">
            <?= Csrf::field() ?>
            <button type="submit" class="badge-btn badge badge-<?= e($row['status']) ?>" title="Toggle publish">
              <?= e($row['status']) ?>
            </button>
          </form>
        </td>
        <td>
          <form method="post" action="/admin/properties/<?= e($id) ?>/toggle-featured" class="inline-form">
            <?= Csrf::field() ?>
            <button type="submit" class="star-btn <?= $row['is_featured'] ? 'on' : '' ?>" title="Toggle featured" aria-label="Toggle featured">
              <svg viewBox="0 0 24 24" fill="<?= $row['is_featured'] ? 'currentColor' : 'none' ?>" stroke="currentColor" stroke-width="1.6"><path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.8L12 3.5z"/></svg>
            </button>
          </form>
        </td>
        <td class="muted"><?= e(number_format((int)$row['view_count'])) ?></td>
        <td class="ta-r nowrap">
          <a href="/admin/properties/<?= e($id) ?>/edit" class="btn btn-ghost btn-sm">Edit</a>
          <form method="post" action="/admin/properties/<?= e($id) ?>/delete" class="inline-form" data-confirm="Delete this property and its images?">
            <?= Csrf::field() ?>
            <button type="submit" class="btn btn-danger btn-sm">Delete</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
  </div>

  <?php if ($meta['total_pages'] > 1): ?>
  <div class="pagination">
    <?php
    $qs = static function (int $page) use ($filters): string {
        return '/admin/properties?' . http_build_query(array_filter([
            'q'        => $filters['q'],
            'status'   => $filters['status'],
            'type'     => $filters['transaction_type'],
            'category' => $filters['category'],
            'page'     => $page,
        ], static fn($v) => $v !== '' && $v !== null));
    };
    ?>
    <?php for ($p = 1; $p <= $meta['total_pages']; $p++): ?>
      <?php if ($p === $meta['page']): ?>
      <span class="page current"><?= e($p) ?></span>
      <?php else: ?>
      <a class="page" href="<?= e($qs($p)) ?>"><?= e($p) ?></a>
      <?php endif; ?>
    <?php endfor; ?>
  </div>
  <?php endif; ?>
</div>

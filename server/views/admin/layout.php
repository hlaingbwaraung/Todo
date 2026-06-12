<?php

use App\Core\Csrf;

/** @var string $content */
$title = $title ?? 'Admin';
$active = $active ?? '';
$admin = $admin ?? null;

$navItems = [
    'dashboard'    => ['href' => '/admin', 'label' => 'Dashboard',
        'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></svg>'],
    'properties'   => ['href' => '/admin/properties', 'label' => 'Properties',
        'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 11l9-8 9 8"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/></svg>'],
    'inquiries'    => ['href' => '/admin/inquiries', 'label' => 'Inquiries',
        'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 5h16a1 1 0 011 1v10a1 1 0 01-1 1H9l-5 4V6a1 1 0 011-1z"/><path d="M8 9.5h8M8 13h5"/></svg>'],
    'reservations' => ['href' => '/admin/reservations', 'label' => 'Reservations',
        'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9.5h18M8 3v4M16 3v4"/><path d="M9 14.5l2 2 4-4"/></svg>'],
    'users'        => ['href' => '/admin/users', 'label' => 'Users',
        'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.8-3.2 3.4-5 6.5-5s5.7 1.8 6.5 5"/><circle cx="17.5" cy="9" r="2.5"/><path d="M16.5 14.5c2.6.2 4.4 1.7 5 4.5"/></svg>'],
    'categories'   => ['href' => '/admin/categories', 'label' => 'Categories',
        'icon' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3.5 6.5L12 3l8.5 3.5L12 10 3.5 6.5z"/><path d="M3.5 12L12 15.5 20.5 12"/><path d="M3.5 17.5L12 21l8.5-3.5"/></svg>'],
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($title) ?> · HappyHome Admin</title>
<link rel="stylesheet" href="/assets/admin.css">
</head>
<body>
<div class="shell">
  <aside class="sidebar">
    <div class="brand">
      <span class="brand-mark">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-8 9 8"/><path d="M5 9.5V21h14V9.5"/></svg>
      </span>
      <span class="brand-text">HappyHome<small>不動産管理</small></span>
    </div>
    <nav class="nav">
      <?php foreach ($navItems as $key => $item): ?>
      <a href="<?= e($item['href']) ?>" class="nav-link<?= $active === $key ? ' active' : '' ?>">
        <span class="nav-icon"><?= $item['icon'] ?></span>
        <span><?= e($item['label']) ?></span>
      </a>
      <?php endforeach; ?>
    </nav>
    <div class="sidebar-footer">
      <div class="whoami">
        <span class="avatar"><?= e(mb_substr((string)($admin['name'] ?? 'A'), 0, 1)) ?></span>
        <div class="whoami-meta">
          <strong><?= e($admin['name'] ?? '') ?></strong>
          <small><?= e($admin['email'] ?? '') ?></small>
        </div>
      </div>
      <form method="post" action="/admin/logout">
        <?= Csrf::field() ?>
        <button type="submit" class="btn btn-ghost btn-sm btn-block">Sign out</button>
      </form>
    </div>
  </aside>
  <main class="main">
    <header class="topbar">
      <h1 class="page-title"><?= e($title) ?></h1>
      <span class="topbar-date"><?= e(date('Y年n月j日 (D)')) ?></span>
    </header>
    <div class="content">
      <?= $content ?>
    </div>
  </main>
</div>
<script src="/assets/admin.js"></script>
</body>
</html>

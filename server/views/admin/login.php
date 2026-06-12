<?php

use App\Core\Csrf;

/** @var ?string $error */
/** @var string $email */
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sign in · HappyHome Admin</title>
<link rel="stylesheet" href="/assets/admin.css">
</head>
<body class="login-body">
<div class="login-wrap">
  <div class="login-card">
    <div class="login-brand">
      <span class="brand-mark brand-mark-lg">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11l9-8 9 8"/><path d="M5 9.5V21h14V9.5"/></svg>
      </span>
      <h1>HappyHome <span class="ja">不動産管理</span></h1>
      <p class="login-sub">Sign in to the administration console</p>
    </div>
    <?php if (!empty($error)): ?>
    <div class="alert alert-error"><?= e($error) ?></div>
    <?php endif; ?>
    <form method="post" action="/admin/login" class="login-form">
      <?= Csrf::field() ?>
      <label class="field">
        <span class="field-label">Email</span>
        <input type="email" name="email" value="<?= e($email ?? '') ?>" required autofocus autocomplete="username">
      </label>
      <label class="field">
        <span class="field-label">Password</span>
        <input type="password" name="password" required autocomplete="current-password">
      </label>
      <button type="submit" class="btn btn-primary btn-block">Sign in</button>
    </form>
  </div>
  <p class="login-foot">&copy; <?= e(date('Y')) ?> HappyHome Realty K.K.</p>
</div>
</body>
</html>

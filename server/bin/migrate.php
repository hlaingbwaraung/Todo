<?php

declare(strict_types=1);

/**
 * Creates all tables for the configured DB driver.
 *   php server/bin/migrate.php            # safe: refuses to touch an existing schema
 *   php server/bin/migrate.php --fresh    # DROPS all tables first (destroys all data)
 */

$base = dirname(__DIR__);
require $base . '/config.php';

spl_autoload_register(static function (string $class) use ($base): void {
    if (str_starts_with($class, 'App\\')) {
        $path = $base . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (is_file($path)) {
            require $path;
        }
    }
});

use App\Core\Database;

$driver = Database::driver();
$schemaFile = $base . '/database/schema.' . $driver . '.sql';
if (!is_file($schemaFile)) {
    fwrite(STDERR, "Schema file not found: $schemaFile\n");
    exit(1);
}

$sql = (string)file_get_contents($schemaFile);
$pdo = Database::pdo();
$fresh = in_array('--fresh', $argv, true);

$tables = ['devices', 'reservations', 'inquiries', 'favorites', 'property_images', 'properties', 'categories', 'users'];
$existing = false;
try {
    $pdo->query('SELECT 1 FROM users LIMIT 1');
    $existing = true;
} catch (PDOException) {
    // Table absent: clean database.
}

if ($existing && !$fresh) {
    fwrite(STDERR, "Database schema already exists — nothing to do.\n");
    fwrite(STDERR, "To DROP every table and recreate from scratch (DESTROYS ALL DATA), run:\n");
    fwrite(STDERR, "  php server/bin/migrate.php --fresh\n");
    exit(1);
}

if ($fresh) {
    if ($driver === 'mysql') {
        $pdo->exec('SET FOREIGN_KEY_CHECKS = 0');
    }
    foreach ($tables as $table) {
        $pdo->exec("DROP TABLE IF EXISTS $table");
    }
    if ($driver === 'mysql') {
        $pdo->exec('SET FOREIGN_KEY_CHECKS = 1');
    }
    echo "Dropped existing tables (--fresh).\n";
}

// Split on statement-terminating semicolons (none of our statements embed ';').
$statements = array_filter(
    array_map('trim', preg_split('/;\s*(?:\r?\n|$)/', $sql) ?: []),
    static fn(string $s) => $s !== '' && !str_starts_with($s, '--')
);

$count = 0;
foreach ($statements as $statement) {
    $pdo->exec($statement);
    $count++;
}

echo "Migrated ($driver): executed $count statements.\n";

<?php

declare(strict_types=1);

/**
 * Creates all tables for the configured DB driver.
 *   php server/bin/migrate.php
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

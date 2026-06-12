<?php

declare(strict_types=1);

namespace App\Core;

final class View
{
    /**
     * Render an admin page inside the layout.
     */
    public static function render(string $template, array $data = []): never
    {
        $viewsDir = dirname(__DIR__, 2) . '/views';
        $templateFile = $viewsDir . '/' . $template . '.php';

        extract($data, EXTR_SKIP);
        ob_start();
        require $templateFile;
        $content = ob_get_clean();

        require $viewsDir . '/admin/layout.php';
        exit;
    }

    /**
     * Render a standalone view (no layout), e.g. the login page.
     */
    public static function renderBare(string $template, array $data = []): never
    {
        $viewsDir = dirname(__DIR__, 2) . '/views';
        extract($data, EXTR_SKIP);
        require $viewsDir . '/' . $template . '.php';
        exit;
    }
}

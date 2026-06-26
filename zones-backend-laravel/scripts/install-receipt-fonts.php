<?php

/**
 * Generates dompdf font metrics for Amiri Arabic fonts.
 * Requires Amiri-Regular.ttf and Amiri-Bold.ttf in storage/fonts/.
 *
 * Download (if missing):
 *   curl -L -o storage/fonts/Amiri-Regular.ttf "https://cdn.jsdelivr.net/fontsource/fonts/amiri@5.0.8/arabic-400-normal.ttf"
 *   curl -L -o storage/fonts/Amiri-Bold.ttf "https://cdn.jsdelivr.net/fontsource/fonts/amiri@5.0.8/arabic-700-normal.ttf"
 */

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use FontLib\Font;

$fontDir = storage_path('fonts');
if (! is_dir($fontDir)) {
    mkdir($fontDir, 0755, true);
}

$downloadUrls = [
    'Amiri-Regular.ttf' => 'https://cdn.jsdelivr.net/fontsource/fonts/amiri@5.0.8/arabic-400-normal.ttf',
    'Amiri-Bold.ttf' => 'https://cdn.jsdelivr.net/fontsource/fonts/amiri@5.0.8/arabic-700-normal.ttf',
];

foreach ($downloadUrls as $filename => $url) {
    $path = $fontDir.DIRECTORY_SEPARATOR.$filename;
    if (is_file($path) && filesize($path) > 10000) {
        continue;
    }

    $content = @file_get_contents($url);
    if ($content === false || strlen($content) < 10000) {
        echo "FAIL download: {$filename}\n";
        exit(1);
    }

    file_put_contents($path, $content);
    echo "DOWNLOADED: {$filename}\n";
}

$fonts = [
    ['file' => 'Amiri-Regular.ttf', 'family' => 'amiri', 'variant' => 'normal'],
    ['file' => 'Amiri-Bold.ttf', 'family' => 'amiri', 'variant' => 'bold'],
];

$installed = [];

foreach ($fonts as $fontDef) {
    $path = $fontDir.DIRECTORY_SEPARATOR.$fontDef['file'];
    if (! is_file($path)) {
        echo "MISSING: {$path}\n";
        exit(1);
    }

    $baseName = pathinfo($fontDef['file'], PATHINFO_FILENAME);
    $ufmPath = $fontDir.DIRECTORY_SEPARATOR.$baseName;

    $font = Font::load($path);
    if (! $font) {
        echo "FAIL parse: {$fontDef['file']}\n";
        exit(1);
    }

    $font->parse();
    $font->saveAdobeFontMetrics($ufmPath.'.ufm');
    $font->close();

    if (! is_file($ufmPath.'.ufm')) {
        echo "FAIL metrics: {$fontDef['file']}\n";
        exit(1);
    }

    $installed[$fontDef['family']][$fontDef['variant']] = $baseName;
    echo "OK: {$baseName}.ufm\n";
}

$userFontsPath = $fontDir.'/installed-fonts.json';
$existing = is_readable($userFontsPath)
    ? json_decode((string) file_get_contents($userFontsPath), true)
    : [];

if (! is_array($existing)) {
    $existing = [];
}

foreach ($installed as $family => $variants) {
    $existing[$family] = array_merge($existing[$family] ?? [], $variants);
}

file_put_contents(
    $userFontsPath,
    json_encode($existing, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
);

echo "Updated: {$userFontsPath}\n";
echo "Done — Arabic receipt fonts ready.\n";

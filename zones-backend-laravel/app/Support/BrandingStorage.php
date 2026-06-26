<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class BrandingStorage
{
    /** @var list<string> */
    private const ALLOWED_EXTENSIONS = ['png', 'jpg', 'jpeg', 'svg'];

    public static function storeFromUpload(UploadedFile $file, ?string $oldPath = null): string
    {
        $extension = strtolower($file->getClientOriginalExtension() ?: 'png');
        if ($extension === 'jpeg') {
            $extension = 'jpg';
        }
        if (! in_array($extension, self::ALLOWED_EXTENSIONS, true)) {
            $extension = 'png';
        }

        $filename = 'zones_logo_'.str_replace('.', '', (string) microtime(true)).'.'.$extension;
        $path = 'branding/'.$filename;

        Storage::disk('public')->putFileAs('branding', $file, $filename);

        self::deleteStoredFile($oldPath);

        return $path;
    }

    public static function deleteStoredFile(?string $path): void
    {
        if ($path === null || $path === '') {
            return;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return;
        }

        if (str_starts_with($path, 'data:image')) {
            return;
        }

        Storage::disk('public')->delete($path);
    }
}

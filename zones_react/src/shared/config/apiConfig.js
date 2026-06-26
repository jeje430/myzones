/**
 * Laravel API base URL (same backend as Flutter customer app).
 *
 * Herd: http://zones-backend-laravel.test/api
 * artisan serve: http://127.0.0.1:8000/api
 */
export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://zones-backend-laravel.test/api";

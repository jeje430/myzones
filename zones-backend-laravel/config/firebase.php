<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Firebase service account JSON path
    |--------------------------------------------------------------------------
    |
    | Absolute or storage-relative path to the Firebase Admin service account
    | credentials file. Set FIREBASE_CREDENTIALS in .env (e.g. storage/app/firebase-credentials.json).
    |
    */
    'credentials' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase-credentials.json')),

  /** Firebase project ID (from service account JSON or console). */
    'project_id' => env('FIREBASE_PROJECT_ID'),
];

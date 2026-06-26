/// عنوان API العام — يُضبط **مرة واحدة** ويعمل من أي Wi‑Fi / 4G.
///
/// بعد نشر Laravel على سيرفر (Railway, Forge, VPS, …) ضع الرابط هنا:
///   `https://api.your-domain.com`
///
/// أو مرّره عند التشغيل:
///   `--dart-define=ZONEZ_API_URL=https://api.your-domain.com`
///
/// اتركه فارغاً لاستخدام وضع التطوير المحلي على الكمبيوتر فقط.
const String kZonezPublicApiRoot = '';

/// يُملأ تلقائياً من `--dart-define=ZONEZ_API_URL=...`
const String kZonezPublicApiRootFromDefine = String.fromEnvironment('ZONEZ_API_URL');

import ThemeToggle from "../../../shared/components/ThemeToggle";

export default function SuperAdminAuthShell({ title, subtitle, children }) {
  return (
    <div
      className="relative flex min-h-screen items-center justify-center bg-gradient-to-br from-gray-100 via-white to-[#6B5478]/10 p-4 dark:from-gray-950 dark:via-gray-900 dark:to-[#6B5478]/20"
      style={{ fontFamily: "Cairo, 'Segoe UI', Tahoma, sans-serif" }}
      dir="rtl"
    >
      <div className="absolute start-4 top-4">
        <ThemeToggle compact />
      </div>
      <div className="w-full max-w-md rounded-3xl border border-gray-200 bg-white p-8 shadow-2xl dark:border-gray-700 dark:bg-gray-900">
        <div className="mb-6 text-center">
          <h1 className="text-lg font-extrabold text-gray-900 dark:text-white">{title}</h1>
          {subtitle ? (
            <p className="mt-2 text-xs leading-relaxed text-gray-500 dark:text-gray-400">{subtitle}</p>
          ) : null}
        </div>
        {children}
      </div>
    </div>
  );
}

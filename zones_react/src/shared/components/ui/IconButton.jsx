const TONES = {
  default:
    "text-gray-500 hover:text-[#6B5478] dark:text-gray-400 dark:hover:text-[#c4b5d0]",
  brand: "text-[#6B5478] hover:opacity-80 dark:text-[#c4b5d0] dark:hover:opacity-90",
  danger: "text-red-500 hover:text-red-600 dark:text-red-400 dark:hover:text-red-300",
  warning: "text-orange-500 hover:text-orange-600 dark:text-orange-400 dark:hover:text-orange-300",
  success:
    "text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300",
  muted: "text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300",
};

export default function IconButton({
  icon: Icon,
  label,
  tone = "default",
  size = 19,
  className = "",
  ...props
}) {
  if (!Icon) return null;

  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      className={`inline-flex shrink-0 items-center justify-center rounded-md p-1.5 transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6B5478]/45 focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-40 ${TONES[tone] || TONES.default} ${className}`}
      {...props}
    >
      <Icon size={size} strokeWidth={2.25} />
    </button>
  );
}

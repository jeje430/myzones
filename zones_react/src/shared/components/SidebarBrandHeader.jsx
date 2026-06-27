import PlatformLogo from "./PlatformLogo";
import SidebarCollapseToggle from "./SidebarCollapseToggle";

/**
 * هيدر القائمة — ZONES في المنتصف، زر الطي في الزاوية العلوية الداخلية (يسار = نحو المحتوى).
 */
export default function SidebarBrandHeader({ subtitle, onMenuToggle, sidebarOpen = true }) {
  return (
    <div className="relative bg-gradient-to-l from-[#6B5478] to-[#836a90] px-5 py-6">
      {onMenuToggle ? (
        <SidebarCollapseToggle
          sidebarOpen={sidebarOpen}
          onClick={onMenuToggle}
          className="absolute left-3 top-3 z-10"
        />
      ) : null}

      <div className="flex flex-col items-center gap-2.5 text-center">
        <span className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-full bg-white shadow-sm ring-1 ring-white/40">
          <PlatformLogo variant="avatar" />
        </span>
        <div className="text-white">
          <p className="text-lg font-extrabold leading-none tracking-wide">ZONES</p>
          <p className="mt-1.5 text-[11px] font-semibold text-white/80">{subtitle}</p>
        </div>
      </div>
    </div>
  );
}

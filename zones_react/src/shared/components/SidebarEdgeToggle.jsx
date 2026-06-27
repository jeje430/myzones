import SidebarCollapseToggle from "./SidebarCollapseToggle";

export default function SidebarEdgeToggle({ onMenuToggle }) {
  if (!onMenuToggle) return null;

  return (
    <SidebarCollapseToggle
      sidebarOpen={false}
      onClick={onMenuToggle}
      className="fixed end-0 top-1/2 z-50 -translate-y-1/2 shadow-md"
    />
  );
}

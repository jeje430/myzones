import { useEffect, useMemo, useState } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  AlertTriangle,
  BarChart3,
  Bell,
  Building2,
  ChevronDown,
  Home,
  LogOut,
  Tag,
  Trophy,
  MessageCircle,
  User,
  Users,
} from "lucide-react";
import { zonesConfirm } from "../utils/zonesAlerts";
import { getManagerMenu } from "../config/managerNavigation";
import { clearAuthSession } from "../../features/auth/data/mockUsersStorage";
import { useManagerPaths } from "../tenant/ManagerWorkspaceProvider";

import SidebarBrandHeader from "./SidebarBrandHeader";

function buildExactPaths(routes) {
  return [
    routes.employees,
    routes.reception,
    routes.employeesArchive,
    routes.offers,
    routes.interaction,
    routes.tournaments,
    routes.tournamentsParticipants,
    routes.finance,
    routes.expenses,
    routes.payments,
    routes.analysis,
    routes.revenues,
    routes.faults,
    routes.faultsArchive,
    routes.alertsLog,
    routes.alertsArchive,
    routes.alertsStopBookings,
  ];
}

function pathMatches(pathname, path, search = "", exactPaths = []) {
  if (!path) return false;
  const base = path.split("?")[0];

  if (path.includes("?")) {
    const qs = new URLSearchParams(path.split("?")[1]);
    const current = new URLSearchParams(search);
    for (const [k, v] of qs.entries()) {
      if (current.get(k) !== v) return false;
    }
    return pathname === base;
  }

  if (pathname === base) return true;

  if (exactPaths.includes(base)) return false;

  return pathname.startsWith(`${base}/`);
}

function nodeActive(node, pathname, search = "", exactPaths = []) {
  if (node.path && pathMatches(pathname, node.path, search, exactPaths)) return true;
  return (node.children || []).some((c) => nodeActive(c, pathname, search, exactPaths));
}

function collectOpenIds(nodes, pathname, acc = {}, search = "", exactPaths = []) {
  nodes.forEach((node) => {
    if (node.children?.length) {
      if (nodeActive(node, pathname, search, exactPaths)) acc[node.id || node.label] = true;
      collectOpenIds(node.children, pathname, acc, search, exactPaths);
    }
  });
  return acc;
}

const topLinkClass = ({ isActive }) =>
  `flex items-center gap-2.5 rounded-lg px-3 py-2.5 text-[13px] font-semibold transition ${
    isActive
      ? "bg-[#6B5478] text-white shadow-sm"
      : "text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
  }`;

function sidebarMainItemClass(active) {
  return `flex w-full items-center justify-between gap-2 rounded-lg px-3 py-2.5 text-[13px] font-semibold transition ${
    active
      ? "bg-[#6B5478]/10 text-[#6B5478] dark:bg-[#6B5478]/20"
      : "text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800"
  }`;
}

function StandaloneMenuLink({ to, icon: Icon, label, pathname, onNavigate }) {
  const active = pathname === to || pathname.startsWith(`${to}/`);
  return (
    <NavLink to={to} end onClick={onNavigate} className={sidebarMainItemClass(active)}>
      <span className="flex items-center gap-2.5">
        <Icon size={18} strokeWidth={2} />
        {label}
      </span>
    </NavLink>
  );
}

function NestedItems({ items, depth, open, toggle, onNavigate, pathname, search }) {
  return (
    <div className={`space-y-0.5 ${depth > 0 ? "mt-0.5 pe-2" : ""}`}>
      {items.map((item) => {
        const key = item.id || item.path || item.label;

        if (item.action === "logout") {
          return (
            <button
              key={key}
              type="button"
              onClick={onNavigate.logout}
              className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs font-semibold text-red-600 transition hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/30"
              style={{ paddingInlineStart: `${12 + depth * 10}px` }}
            >
              <LogOut size={15} />
              {item.label}
            </button>
          );
        }

        if (item.children?.length) {
          const id = item.id || item.label;
          const isOpen = open[id];
          const active = nodeActive(item, pathname, search);
          return (
            <div key={key}>
              <div className="flex items-center gap-1">
                {item.path ? (
                  <NavLink
                    to={item.path}
                    end
                    onClick={onNavigate.close}
                    className={({ isActive }) =>
                      `flex flex-1 items-center gap-2 rounded-lg px-3 py-2 text-xs font-semibold transition ${
                        isActive || active
                          ? "bg-[#6B5478]/10 text-[#6B5478]"
                          : "text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800"
                      }`
                    }
                    style={{ paddingInlineStart: `${12 + depth * 10}px` }}
                  >
                    <span className="h-1.5 w-1.5 rounded-full bg-current opacity-60" />
                    {item.label}
                  </NavLink>
                ) : (
                  <button
                    type="button"
                    onClick={() => toggle(id)}
                    className={`flex flex-1 items-center justify-between gap-2 rounded-lg px-3 py-2 text-xs font-semibold transition ${
                      active
                        ? "text-[#6B5478]"
                        : "text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800"
                    }`}
                    style={{ paddingInlineStart: `${12 + depth * 10}px` }}
                  >
                    <span className="flex items-center gap-2">
                      <span className="h-1.5 w-1.5 rounded-full bg-current opacity-60" />
                      {item.label}
                    </span>
                    <ChevronDown size={14} className={`transition ${isOpen ? "rotate-180" : ""}`} />
                  </button>
                )}
                {item.path ? (
                  <button
                    type="button"
                    onClick={() => toggle(id)}
                    className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
                    aria-label="توسيع"
                  >
                    <ChevronDown size={14} className={`transition ${isOpen ? "rotate-180" : ""}`} />
                  </button>
                ) : null}
              </div>
              {isOpen ? (
                <NestedItems
                  items={item.children}
                  depth={depth + 1}
                  open={open}
                  toggle={toggle}
                  onNavigate={onNavigate}
                  pathname={pathname}
                  search={search}
                />
              ) : null}
            </div>
          );
        }

        return (
          <NavLink
            key={key}
            to={item.path}
            end
            onClick={onNavigate.close}
            className={({ isActive }) =>
              `flex items-center gap-2 rounded-lg px-3 py-2 text-xs font-semibold transition ${
                isActive
                  ? "bg-[#6B5478]/10 text-[#6B5478]"
                  : "text-gray-500 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800"
              }`
            }
            style={{ paddingInlineStart: `${12 + depth * 10}px` }}
          >
            <span className="h-1.5 w-1.5 rounded-full bg-current opacity-60" />
            {item.label}
          </NavLink>
        );
      })}
    </div>
  );
}

function MenuGroup({ group, icon: Icon, open, toggle, onNavigate, pathname, search }) {
  const id = group.id;
  const isOpen = open[id];
  const active = nodeActive(group, pathname, search);
  return (
    <div>
      <button type="button" onClick={() => toggle(id)} className={sidebarMainItemClass(active)}>
        <span className="flex items-center gap-2.5">
          <Icon size={18} strokeWidth={2} />
          {group.label}
        </span>
        <ChevronDown size={15} className={`shrink-0 transition ${isOpen ? "rotate-180" : ""}`} />
      </button>
      {isOpen ? (
        <NestedItems
          items={group.children}
          depth={0}
          open={open}
          toggle={toggle}
          onNavigate={onNavigate}
          pathname={pathname}
          search={search}
        />
      ) : null}
    </div>
  );
}

export default function ManagerSidebar({ onNavigate, onMenuToggle }) {
  const location = useLocation();
  const navigate = useNavigate();
  const pathname = location.pathname;
  const search = location.search;
  const { managerId, routes } = useManagerPaths();
  const MANAGER_MENU = useMemo(() => getManagerMenu(managerId), [managerId]);
  const exactPaths = useMemo(() => buildExactPaths(routes), [routes]);

  const MENU_GROUPS = useMemo(
    () => [
      MANAGER_MENU.hall,
      MANAGER_MENU.staff,
      MANAGER_MENU.faults,
      MANAGER_MENU.alerts,
      MANAGER_MENU.tournaments,
      MANAGER_MENU.finance,
    ],
    [MANAGER_MENU],
  );

  const initialOpen = useMemo(() => {
    const acc = {};
    MENU_GROUPS.forEach((g) => {
      if (nodeActive(g, pathname, search, exactPaths)) acc[g.id] = true;
    });
    collectOpenIds(
      MENU_GROUPS.flatMap((g) => g.children || []),
      pathname,
      acc,
      search,
      exactPaths,
    );
    return acc;
  }, [pathname, search, MENU_GROUPS, exactPaths]);

  const [open, setOpen] = useState(initialOpen);

  useEffect(() => {
    setOpen((prev) => ({ ...prev, ...initialOpen }));
  }, [initialOpen]);

  const toggle = (id) => setOpen((o) => ({ ...o, [id]: !o[id] }));

  const handleLogout = async () => {
    const confirmed = await zonesConfirm({
      title: "تسجيل الخروج؟",
      text: "سيتم إنهاء جلستك الحالية.",
      confirmText: "تسجيل الخروج",
      cancelText: "إلغاء",
      danger: true,
    });
    if (!confirmed) return;
    clearAuthSession(managerId);
    onNavigate?.();
    navigate("/manager/login", { replace: true });
  };

  const navHandlers = { close: onNavigate, logout: handleLogout };

  return (
    <div
      className="relative flex h-full w-full flex-col overflow-visible border-s border-gray-200 bg-white shadow-xl dark:border-gray-800 dark:bg-gray-900 lg:shadow-none"
      dir="rtl"
    >
      <SidebarBrandHeader subtitle="لوحة المدير" onMenuToggle={onMenuToggle} />

      <nav className="flex-1 space-y-0.5 overflow-y-auto px-3 py-3">
        <NavLink to={MANAGER_MENU.dashboard.path} onClick={onNavigate} className={topLinkClass}>
          <Home size={18} strokeWidth={2} />
          {MANAGER_MENU.dashboard.label}
        </NavLink>

        <MenuGroup
          group={MANAGER_MENU.hall}
          icon={Building2}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />

        <StandaloneMenuLink
          to={MANAGER_MENU.interaction.path}
          icon={MessageCircle}
          label={MANAGER_MENU.interaction.label}
          pathname={pathname}
          onNavigate={onNavigate}
        />

        <MenuGroup
          group={MANAGER_MENU.staff}
          icon={Users}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />

        <MenuGroup
          group={MANAGER_MENU.faults}
          icon={AlertTriangle}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />

        <MenuGroup
          group={MANAGER_MENU.alerts}
          icon={Bell}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />

        <StandaloneMenuLink
          to={MANAGER_MENU.offers.path}
          icon={Tag}
          label={MANAGER_MENU.offers.label}
          pathname={pathname}
          onNavigate={onNavigate}
        />

        <MenuGroup
          group={MANAGER_MENU.tournaments}
          icon={Trophy}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />

        <MenuGroup
          group={MANAGER_MENU.finance}
          icon={BarChart3}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />

        <MenuGroup
          group={{ ...MANAGER_MENU.account, icon: User }}
          icon={User}
          open={open}
          toggle={toggle}
          onNavigate={navHandlers}
          pathname={pathname}
          search={search}
        />
      </nav>

      <div className="border-t border-gray-100 px-3 py-3 dark:border-gray-800">
        <p className="text-center text-[10px] text-gray-400">GameZones © 2026</p>
      </div>
    </div>
  );
}

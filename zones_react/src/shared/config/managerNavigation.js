/** مسارات واجهة مدير الصالة — معزولة حسب user.id في الرابط */
export function getManagerRoutes(managerId) {
  const base = `/manager/${managerId}`;
  return {
    dashboard: `${base}/dashboard`,
    profile: `${base}/profile`,
    changePassword: `${base}/profile/change-password`,
    lounge: `${base}/lounge`,
    loungeEdit: `${base}/lounge/edit`,
    devices: `${base}/devices`,
    packages: `${base}/packages`,
    hallArchive: `${base}/hall/archive`,
    reception: `${base}/employees/reception`,
    employees: `${base}/employees`,
    employeesArchive: `${base}/employees/archive`,
    offers: `${base}/offers`,
    tournaments: `${base}/tournaments`,
    tournamentsParticipants: `${base}/tournaments/participants`,
    finance: `${base}/finance`,
    expenses: `${base}/finance/expenses`,
    payments: `${base}/finance/payments`,
    analysis: `${base}/finance/net-profit`,
    revenues: `${base}/finance/revenues`,
    emergency: `${base}/emergency`,
    faults: `${base}/faults`,
    faultsArchive: `${base}/faults/archive`,
    alertsLog: `${base}/alerts/log`,
    alertsArchive: `${base}/alerts/archive`,
    alertsStopBookings: `${base}/alerts/stop-bookings`,
    interaction: `${base}/interaction`,
  };
}

/** للتوافق مع الكود القديم — يستخدم جلسة التبويب الحالي */
export const MANAGER_ROUTES = getManagerRoutes(
  typeof window !== "undefined"
    ? window.location.pathname.match(/^\/manager\/(\d+)/)?.[1] ?? "0"
    : "0",
);

/** شجرة القائمة — نفس أسلوب لوحة الأدمن */
export function getManagerMenu(managerId) {
  const R = getManagerRoutes(managerId);
  return {
    dashboard: { label: "لوحة التحكم", path: R.dashboard },
    account: {
      id: "account",
      label: "حسابي",
      children: [
        { label: "ملف شخصي", path: R.profile },
        { label: "تغيير كلمة المرور", path: R.changePassword },
        { label: "تسجيل الخروج", action: "logout" },
      ],
    },
    hall: {
      id: "hall",
      label: "إدارة الصالة",
      children: [
        { id: "lounge", label: "بيانات الصالة", path: R.lounge },
        { id: "devices", label: "أجهزة", path: R.devices },
        { id: "packages", label: "الباقات", path: R.packages },
        { id: "hallArchive", label: "أرشيف", path: R.hallArchive },
      ],
    },
    staff: {
      id: "staff",
      label: "الموظفين",
      children: [
        { id: "employees", label: "الموظفين", path: R.employees },
        { id: "archive", label: "أرشفة", path: R.employeesArchive },
      ],
    },
    faults: {
      id: "faults",
      label: "الأعطال",
      children: [
        { label: "الأعطال", path: R.faults },
        { label: "الأعطال المؤرشفة", path: R.faultsArchive },
      ],
    },
    alerts: {
      id: "alerts",
      label: "إدارة تنبيهات",
      children: [
        { label: "سجل التنبيهات", path: R.alertsLog },
        { label: "أرشفة التنبيهات", path: R.alertsArchive },
        { label: "إيقاف الحجوزات", path: R.alertsStopBookings },
      ],
    },
    offers: { label: "عروض", path: R.offers },
    interaction: { label: "تفاعل", path: R.interaction },
    tournaments: {
      id: "tournaments",
      label: "البطولات",
      children: [
        { label: "عرض البطولات", path: R.tournaments },
        { label: "قائمة المشاركين", path: R.tournamentsParticipants },
      ],
    },
    finance: {
      id: "finance",
      label: "إدارة مالية",
      children: [
        { label: "بيانات المصروف", path: R.expenses },
        { label: "المدفوعات", path: R.payments },
        { label: "تحليل مالي", path: R.analysis },
      ],
    },
  };
}

export const MANAGER_MENU = getManagerMenu(
  typeof window !== "undefined"
    ? window.location.pathname.match(/^\/manager\/(\d+)/)?.[1] ?? "0"
    : "0",
);

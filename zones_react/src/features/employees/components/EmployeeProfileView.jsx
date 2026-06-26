import {
  AlertTriangle,
  Building2,
  CalendarDays,
  CheckCircle2,
  Clock,
  Mail,
  Pencil,
  Phone,
  Save,
  Trash2,
  User,
} from "lucide-react";
import ConfirmModal from "../../super-admin/components/ui/ConfirmModal";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import ProfileAvatarEditor from "../../../shared/components/ProfileAvatarEditor";
import { updateUserProfile } from "../../auth/data/mockUsersStorage";
import { IconField } from "../../../components/ui/icon-field";
import {
  formatDateAr,
  formatSalary,
  roleLabel,
  shiftLabel,
  statusLabel,
  workDaysLabel,
} from "../data/employeeMeta";

export default function EmployeeProfileView({
  roleBadgeLabel,
  profile,
}) {
  const {
    user,
    employee,
    hallName,
    fullName,
    setFullName,
    email,
    phone,
    setPhone,
    avatar,
    setAvatar,
    editing,
    setEditing,
    deleteOpen,
    setDeleteOpen,
    loading,
    apiSession,
    joinDate,
    lastLogin,
    save,
    deleteAccount,
  } = profile;

  if (!user) return null;

  if (loading) {
    return (
      <div>
        <PageHeader title="حسابي" description="إدارة بياناتك الشخصية — بيانات الوظيفة يحددها مدير الصالة." />
        <div className="rounded-2xl border border-gray-200 bg-white p-10 text-center text-sm font-bold text-gray-400 dark:border-gray-800 dark:bg-gray-900">
          جاري تحميل الملف الشخصي…
        </div>
      </div>
    );
  }

  return (
    <div>
      <PageHeader title="حسابي" description="إدارة بياناتك الشخصية — بيانات الوظيفة يحددها مدير الصالة." />

      <div className="grid gap-4 lg:grid-cols-3">
        <section className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900 lg:col-span-2">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="flex items-center gap-2 text-sm font-extrabold text-gray-900 dark:text-white">
              <User size={16} className="text-[#6B5478]" /> المعلومات الشخصية
            </h2>
            {!editing ? (
              <button
                type="button"
                onClick={() => setEditing(true)}
                className="flex items-center gap-1.5 rounded-xl border border-gray-300 px-3 py-1.5 text-[11px] font-bold text-gray-700 transition hover:bg-gray-50 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-gray-800"
              >
                <Pencil size={13} /> تعديل
              </button>
            ) : (
              <button
                type="button"
                onClick={save}
                className="flex items-center gap-1.5 rounded-xl bg-[#6B5478] px-3 py-1.5 text-[11px] font-bold text-white transition hover:bg-[#5a4665]"
              >
                <Save size={13} /> حفظ
              </button>
            )}
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <IconField
              label="الاسم الكامل"
              icon={User}
              value={fullName}
              onChange={setFullName}
              disabled={!editing}
            />
            <IconField
              label="البريد الإلكتروني"
              icon={Mail}
              value={email}
              onChange={() => {}}
              disabled
              type="email"
              ltr
              hint={apiSession ? "يُحدَّد من حساب الدعوة — للقراءة فقط" : undefined}
            />
            <IconField
              label="رقم الهاتف"
              icon={Phone}
              value={phone}
              onChange={setPhone}
              disabled={!editing}
              ltr
            />
            <IconField
              label="اسم الصالة"
              icon={Building2}
              value={hallName}
              disabled
              hint="يُحدَّد من إعدادات الصالة — للقراءة فقط"
            />
          </div>

          <div className="mt-6 border-t border-gray-100 pt-5 dark:border-gray-800">
            <h3 className="mb-3 text-xs font-extrabold text-gray-700 dark:text-gray-200">
              بيانات يتحكم فيها المدير
            </h3>
            <div className="grid gap-4 sm:grid-cols-2">
              <IconField label="نوع الموظف" value={roleLabel(employee?.role || user.role)} disabled />
              <IconField label="توقيت الدوام" value={shiftLabel(employee?.shift)} disabled />
              <IconField label="أيام العمل" value={workDaysLabel(employee?.workDays)} disabled />
              <IconField label="ساعات العمل" icon={Clock} value={employee?.workHours || "—"} disabled ltr />
              <IconField label="الراتب الشهري" value={formatSalary(employee?.salary)} disabled />
              <IconField label="الحالة" value={statusLabel(employee?.status)} disabled />
            </div>
          </div>
        </section>

        <section className="rounded-2xl border border-gray-200 bg-white p-5 text-center shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <h2 className="mb-4 text-right text-sm font-extrabold text-gray-900 dark:text-white">ملخص الملف الشخصي</h2>
          <ProfileAvatarEditor
            avatarUrl={avatar}
            fullName={fullName}
            onAvatarChange={setAvatar}
            useApi={apiSession}
            onLocalAvatar={(url) => {
              setAvatar(url);
              if (user?.id) updateUserProfile(user.id, { avatar: url });
            }}
          />

          <h3 className="mt-3 text-base font-extrabold text-gray-900 dark:text-white">{fullName}</h3>
          <div className="mt-1 flex items-center justify-center gap-2">
            <span className="text-xs font-bold text-[#6B5478]">{roleBadgeLabel}</span>
            <span className="flex items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-bold text-emerald-600 dark:text-emerald-400">
              <CheckCircle2 size={11} /> {statusLabel(employee?.status) || "نشط"}
            </span>
          </div>

          <div className="mt-4 space-y-2 border-t border-gray-100 pt-4 text-right dark:border-gray-800">
            <div className="flex items-center gap-2 text-xs text-gray-500">
              <CalendarDays size={14} className="text-[#6B5478]" />
              تاريخ الانضمام:
              <strong className="text-gray-800 dark:text-gray-200" dir="ltr">
                {formatDateAr(joinDate)}
              </strong>
            </div>
            <div className="flex items-center gap-2 text-xs text-gray-500">
              <Clock size={14} className="text-[#6B5478]" />
              آخر تسجيل دخول:
              <strong className="text-gray-800 dark:text-gray-200">{lastLogin}</strong>
            </div>
          </div>
        </section>

        {!apiSession ? (
          <section className="rounded-2xl border border-red-200 bg-red-50/40 p-5 shadow-sm dark:border-red-900/40 dark:bg-red-950/10 lg:col-span-3">
            <h2 className="mb-1 flex items-center gap-2 text-sm font-extrabold text-red-700 dark:text-red-300">
              <Trash2 size={16} /> حذف الحساب
            </h2>
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <p className="flex items-start gap-2 text-[11px] leading-relaxed text-red-700/90 dark:text-red-300/90">
                <AlertTriangle size={15} className="mt-0.5 shrink-0" />
                حذف الحساب إجراء نهائي يؤدي إلى إزالة جميع بياناتك بشكل دائم ولا يمكن التراجع عنه.
              </p>
              <button
                type="button"
                onClick={() => setDeleteOpen(true)}
                className="flex shrink-0 items-center justify-center gap-2 rounded-xl bg-red-600 px-5 py-2.5 text-xs font-bold text-white transition hover:bg-red-700"
              >
                <Trash2 size={14} /> حذف الحساب نهائياً
              </button>
            </div>
          </section>
        ) : null}
      </div>

      <ConfirmModal
        open={deleteOpen}
        title="حذف حسابك؟"
        message="سيتم حذف بيانات الدخول والملف المرتبط. لا يمكن التراجع عن هذا الإجراء."
        confirmLabel="حذف نهائياً"
        danger
        onConfirm={deleteAccount}
        onCancel={() => setDeleteOpen(false)}
      />
    </div>
  );
}

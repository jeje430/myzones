import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  AlertTriangle,
  Briefcase,
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
import { zonesSwal, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import ConfirmModal from "../../super-admin/components/ui/ConfirmModal";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import ProfileAvatarEditor from "../../../shared/components/ProfileAvatarEditor";
import {
  deleteUserAccount,
  updateUserProfile,
} from "../../auth/data/mockUsersStorage";
import { isApiStaffSession, updateStaffProfile } from "../../auth/data/staffProfileApi";
import { saveManagerHall } from "../../lounge/data/managerHallStorage";
import { useRequireAccountUser } from "../../../shared/hooks/useAccountUser";
import { IconField } from "../../../components/ui/icon-field";

export function ManagerProfilePage() {
  const navigate = useNavigate();
  const user = useRequireAccountUser();

  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [jobTitle, setJobTitle] = useState("");
  const [avatar, setAvatar] = useState("");
  const [editing, setEditing] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const apiSession = isApiStaffSession();

  useEffect(() => {
    if (!user) return;
    setFullName(user.fullName || "");
    setEmail(user.email || "");
    setPhone(user.phone || "");
    setJobTitle(user.jobTitle || "مدير صالة");
    setAvatar(user.avatar || "");
  }, [user]);

  const joinDate = user?.joinDate || "2024-01-15";
  const lastLogin = new Date().toLocaleString("ar-LY", { hour: "2-digit", minute: "2-digit" });

  const save = async () => {
    if (!user) return;
    if (apiSession) {
      const res = await updateStaffProfile({ fullName, phone });
      if (!res.ok) {
        zonesToastError(res.error);
        return;
      }
    } else {
      const res = updateUserProfile(user.id, { fullName, phone, jobTitle, avatar });
      if (!res.ok) {
        zonesToastError(res.error);
        return;
      }
    }
    saveManagerHall({
      managerName: fullName.trim(),
      phone: phone.trim(),
      email: user.email,
    });
    setEditing(false);
    zonesToastSuccess("تم حفظ التعديلات");
  };

  const deleteAccount = async () => {
    if (!user) return;
    setDeleteOpen(false);
    const { value: password } = await zonesSwal({
      title: "تأكيد الحذف",
      text: "أدخل كلمة المرور الحالية",
      input: "password",
      showCancelButton: true,
      confirmButtonText: "حذف",
      cancelButtonText: "إلغاء",
      confirmButtonColor: "#dc2626",
    });
    if (!password) return;
    const res = deleteUserAccount(user.id, password);
    if (!res.ok) {
      zonesToastError(res.error);
      return;
    }
    navigate("/manager/login", { replace: true, state: { message: "تم حذف الحساب." } });
  };

  if (!user) return null;

  return (
    <>
    <PageHeader title="حسابي" />

      <div className="grid gap-4 lg:grid-cols-3">
        <section className="lg:col-span-2 rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">
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
            <IconField label="الاسم الكامل" icon={User} value={fullName} onChange={setFullName} disabled={!editing} />
            <IconField label="البريد الإلكتروني" icon={Mail} value={email} onChange={() => {}} disabled type="email" ltr />
            <IconField label="رقم الهاتف" icon={Phone} value={phone} onChange={setPhone} disabled={!editing} ltr />
            <IconField label="الوظيفة" icon={Briefcase} value={jobTitle} onChange={setJobTitle} disabled={!editing} />
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
          <div className="mt-1 flex flex-wrap items-center justify-center gap-2">
            <span className="text-xs font-bold text-[#6B5478]">{jobTitle}</span>
            <span className="flex items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-bold text-emerald-600 dark:text-emerald-400">
              <CheckCircle2 size={11} /> نشط
            </span>
          </div>

          <div className="mt-4 space-y-2 border-t border-gray-100 pt-4 text-right dark:border-gray-800">
            <div className="flex items-center gap-2 text-xs text-gray-500">
              <CalendarDays size={14} className="text-[#6B5478]" />
              تاريخ الانضمام:
              <strong className="text-gray-800 dark:text-gray-200" dir="ltr">
                {joinDate}
              </strong>
            </div>
            <div className="flex items-center gap-2 text-xs text-gray-500">
              <Clock size={14} className="text-[#6B5478]" />
              آخر تسجيل دخول:
              <strong className="text-gray-800 dark:text-gray-200">{lastLogin}</strong>
            </div>
          </div>
        </section>

        <section className="lg:col-span-3 rounded-2xl border border-red-200 bg-red-50/40 p-5 shadow-sm dark:border-red-900/40 dark:bg-red-950/10">
          <h2 className="mb-1 flex items-center gap-2 text-sm font-extrabold text-red-700 dark:text-red-300">
            <Trash2 size={16} /> حذف الحساب
          </h2>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="flex items-start gap-2 text-[11px] leading-relaxed text-red-700/90 dark:text-red-300/90">
              <AlertTriangle size={15} className="mt-0.5 shrink-0" />
              حذف الحساب إجراء نهائي. الرجاء التأكد قبل المتابعة.
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
      </div>

      <ConfirmModal
        open={deleteOpen}
        title="حذف حساب المدير؟"
        message="سيتم حذف بيانات الدخول المحلية. لا يمكن التراجع."
        confirmLabel="حذف نهائياً"
        danger
        onConfirm={deleteAccount}
        onCancel={() => setDeleteOpen(false)}
      />
    </>
  );
}
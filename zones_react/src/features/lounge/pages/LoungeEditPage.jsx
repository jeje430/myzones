import { useEffect, useRef, useState } from "react";

import { Link, useNavigate } from "react-router-dom";

import {

  Building2,

  CalendarDays,

  Clock,

  MapPin,

  Phone,

  Save,

} from "lucide-react";

import { zonesConfirm, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";

import { useManagerPaths } from "../../../shared/tenant/ManagerWorkspaceProvider";

import ManagerLayout from "../../../shared/layouts/ManagerLayout";

import PageHeader from "../../super-admin/components/ui/PageHeader";

import { getHallStatusMeta, loadManagerHall, persistManagerHall, clearManagerHall } from "../data/managerHallStorage";



const labelClass = "mb-1.5 block text-[11px] font-bold text-gray-500 dark:text-gray-400";

const inputCls =

  "w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-xs text-gray-800 outline-none focus:border-[#6B5478] focus:ring-2 focus:ring-[#6B5478]/20 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100";

const readOnlyCls =

  "w-full cursor-default rounded-xl border border-gray-200 bg-gray-100 px-3 py-2.5 text-xs text-gray-600 dark:border-gray-700 dark:bg-gray-800/60 dark:text-gray-300";



const MAX_IMAGE_BYTES = 5 * 1024 * 1024;



function Field({ label, icon: Icon, children, hint }) {

  return (

    <div>

      <label className={labelClass}>

        {Icon ? <Icon size={12} className="me-1 inline text-[#6B5478]" /> : null}

        {label}

      </label>

      {children}

      {hint ? <p className="mt-1 text-[10px] text-gray-400">{hint}</p> : null}

    </div>

  );

}



export default function LoungeEditPage() {

  const navigate = useNavigate();

  const { routes } = useManagerPaths();

  const fileRef = useRef(null);

  const previewUrlRef = useRef(null);

  const initial = loadManagerHall();



  const [form, setForm] = useState({ ...initial });

  const [imageFile, setImageFile] = useState(null);

  const [imagePreview, setImagePreview] = useState(initial.image || "");

  const [imageRemoved, setImageRemoved] = useState(false);

  const [saving, setSaving] = useState(false);

  const statusMeta = getHallStatusMeta(form.status);



  useEffect(() => {

    return () => {

      if (previewUrlRef.current) {

        URL.revokeObjectURL(previewUrlRef.current);

      }

    };

  }, []);



  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }));



  const setPreviewFromFile = (file) => {

    if (previewUrlRef.current) {

      URL.revokeObjectURL(previewUrlRef.current);

      previewUrlRef.current = null;

    }

    const objectUrl = URL.createObjectURL(file);

    previewUrlRef.current = objectUrl;

    setImagePreview(objectUrl);

  };



  const onImageChange = (e) => {

    const file = e.target.files?.[0];

    if (!file) return;



    if (file.size > MAX_IMAGE_BYTES) {

      zonesToastError("حجم الصورة يجب أن يكون أقل من 5 ميجابايت");

      e.target.value = "";

      return;

    }



    if (!file.type.startsWith("image/")) {

      zonesToastError("يرجى اختيار ملف صورة صالح");

      e.target.value = "";

      return;

    }



    setImageFile(file);

    setImageRemoved(false);

    setPreviewFromFile(file);

    e.target.value = "";

  };



  const saveChanges = async (e) => {

    e.preventDefault();

    setSaving(true);



    const hadServerImage = Boolean(initial.image?.trim());



    const result = await persistManagerHall({

      hallName: form.hallName.trim(),

      city: form.city.trim(),

      address: form.address.trim(),

      mapLink: form.mapLink.trim(),

      latitude: form.latitude === "" ? null : String(form.latitude ?? "").trim(),

      longitude: form.longitude === "" ? null : String(form.longitude ?? "").trim(),

      phone: form.phone.trim(),

      workHoursFrom: form.workHoursFrom,

      workHoursTo: form.workHoursTo,

      description: form.description?.trim() ?? "",

      completeSetup: true,

      ...(imageFile ? { imageFile } : {}),

      ...(imageRemoved && !imageFile && hadServerImage ? { removeCoverImage: true } : {}),

    });



    setSaving(false);



    if (!result.ok) {

      zonesToastError(result.error || "تعذر حفظ بيانات الصالة");

      return;

    }



    zonesToastSuccess(result.message || "تم حفظ بيانات الصالة");

    navigate(routes.lounge);

  };



  const onClearAll = async () => {

    const confirmed = await zonesConfirm({

      title: "مسح جميع بيانات الصالة؟",

      text: "ستُفرغ كل الحقول والصورة وتختفي الصالة من تطبيق الزبون حتى تضيف البيانات من جديد.",

      confirmText: "مسح البيانات",

      cancelText: "إلغاء",

      danger: true,

    });

    if (!confirmed) return;



    const result = await clearManagerHall();

    if (!result.ok) {

      zonesToastError(result.error || "تعذر مسح البيانات");

      return;

    }



    setForm({ ...result.hall });

    setImageFile(null);

    setImageRemoved(false);

    setImagePreview("");

    zonesToastSuccess(result.message || "تم مسح البيانات");

  };



  const onRemoveImage = () => {

    if (previewUrlRef.current) {

      URL.revokeObjectURL(previewUrlRef.current);

      previewUrlRef.current = null;

    }

    setImageFile(null);

    setImagePreview("");

    setImageRemoved(true);

  };



  return (

    <ManagerLayout>

      <PageHeader title="تعديل بيانات الصالة" description="حدّث معلومات صالتك — تُعرض في تطبيق الزبون والخرائط." />



      <form onSubmit={saveChanges} className="mx-auto max-w-3xl space-y-4">

        <section className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">

          <h2 className="mb-4 text-sm font-extrabold text-gray-900 dark:text-white">صورة الصالة</h2>

          {imagePreview ? (

            <img

              src={imagePreview}

              alt="معاينة صورة الصالة"

              className="mb-3 h-48 w-full rounded-2xl object-cover"

            />

          ) : (

            <div className="mb-3 flex h-48 w-full items-center justify-center rounded-2xl border border-dashed border-gray-300 bg-gray-50 text-xs text-gray-400 dark:border-gray-700 dark:bg-gray-800/50">

              لا توجد صورة — ارفع صورة الغلاف من المعرض

            </div>

          )}

          <input

            ref={fileRef}

            type="file"

            accept="image/jpeg,image/png,image/webp,image/*"

            className="hidden"

            onChange={onImageChange}

          />

          <div className="flex flex-wrap gap-2">

            <button

              type="button"

              onClick={() => fileRef.current?.click()}

              className="rounded-xl border border-gray-300 px-4 py-2 text-xs font-bold text-gray-700 dark:border-gray-700 dark:text-gray-200"

            >

              {imagePreview ? "تغيير الصورة" : "رفع من المعرض"}

            </button>

            {imagePreview ? (

              <button

                type="button"

                onClick={onRemoveImage}

                className="rounded-xl border border-red-300 px-4 py-2 text-xs font-bold text-red-600 dark:border-red-800 dark:text-red-400"

              >

                إزالة الصورة

              </button>

            ) : null}

          </div>

          <p className="mt-2 text-[10px] text-gray-400">

            يُرفع الملف عند الضغط على «حفظ التغييرات» — الحد الأقصى 5 ميجابايت (JPG, PNG, WebP).

          </p>

        </section>



        <section className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">

          <h2 className="mb-4 text-sm font-extrabold text-gray-900 dark:text-white">البيانات الأساسية</h2>

          <div className="grid gap-4 sm:grid-cols-2">

            <Field label="اسم الصالة" icon={Building2}>

              <input

                className={inputCls}

                value={form.hallName}

                onChange={(e) => set("hallName", e.target.value)}

                placeholder="مثال: صالة الأبطال VIP"

              />

            </Field>

            <Field label="المدينة" icon={MapPin}>

              <input

                className={inputCls}

                value={form.city}

                onChange={(e) => set("city", e.target.value)}

                placeholder="طرابلس"

              />

            </Field>

            <div className="sm:col-span-2">

              <Field label="العنوان" icon={MapPin} hint="اكتب العنوان كاملاً كما يظهر للزبون">

                <textarea

                  className={`${inputCls} min-h-[72px] resize-y`}

                  value={form.address}

                  onChange={(e) => set("address", e.target.value)}

                  placeholder="طرابلس — شارع الجمهورية، بجانب..."

                />

              </Field>

            </div>

            <div className="sm:col-span-2">

              <Field label="رابط Google Maps" icon={MapPin}>

                <input

                  className={inputCls}

                  type="url"

                  dir="ltr"

                  value={form.mapLink}

                  onChange={(e) => set("mapLink", e.target.value)}

                  placeholder="https://maps.google.com/..."

                />

              </Field>

            </div>

            <Field

              label="خط العرض (Latitude)"

              icon={MapPin}

              hint="لتطبيق الخريطة — أقرب صالات حسب GPS الزبون"

            >

              <input

                className={inputCls}

                type="text"

                dir="ltr"

                value={form.latitude}

                onChange={(e) => set("latitude", e.target.value)}

                placeholder="32.847556464766186"

              />

            </Field>

            <Field label="خط الطول (Longitude)" icon={MapPin}>

              <input

                className={inputCls}

                type="text"

                dir="ltr"

                value={form.longitude}

                onChange={(e) => set("longitude", e.target.value)}

                placeholder="13.293807008967022"

              />

            </Field>

          </div>

        </section>



        <section className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">

          <h2 className="mb-4 text-sm font-extrabold text-gray-900 dark:text-white">التواصل والتشغيل</h2>

          <div className="grid gap-4 sm:grid-cols-2">

            <Field label="الهاتف" icon={Phone}>

              <input

                className={inputCls}

                dir="ltr"

                value={form.phone}

                onChange={(e) => set("phone", e.target.value)}

                placeholder="091 000 0000"

              />

            </Field>

            <Field label="ساعات العمل — من" icon={Clock}>

              <input

                className={inputCls}

                type="time"

                dir="ltr"

                value={form.workHoursFrom}

                onChange={(e) => set("workHoursFrom", e.target.value)}

              />

            </Field>

            <Field label="ساعات العمل — إلى" icon={Clock}>

              <input

                className={inputCls}

                type="time"

                dir="ltr"

                value={form.workHoursTo}

                onChange={(e) => set("workHoursTo", e.target.value)}

              />

            </Field>

          </div>

        </section>



        <section className="rounded-2xl border border-gray-200 bg-gray-50 p-5 dark:border-gray-800 dark:bg-gray-900/50">

          <h2 className="mb-4 text-sm font-extrabold text-gray-900 dark:text-white">يحددها النظام والإدارة</h2>

          <div className="grid gap-4 sm:grid-cols-2">

            <Field label="تاريخ الانضمام" icon={CalendarDays}>

              <input

                className={readOnlyCls}

                readOnly

                dir="ltr"

                value={form.joinDate?.replaceAll("-", "/") || "—"}

              />

            </Field>

            <Field label="حالة الصالة" icon={Building2}>

              <input className={readOnlyCls} readOnly value={statusMeta.label} />

            </Field>

          </div>

          <p className="mt-3 text-[10px] text-gray-500">

            تاريخ الانضمام يُسجّل تلقائياً ولا يُمسح. حالة الصالة تتحدّث بعد المسح إلى «معلقة» حتى تُعيد إدخال البيانات.

          </p>

        </section>



        <div className="flex flex-wrap justify-between gap-3">

          <button

            type="button"

            onClick={onClearAll}

            className="rounded-xl border border-red-300 px-5 py-2.5 text-xs font-bold text-red-600 dark:border-red-800 dark:text-red-400"

          >

            مسح جميع البيانات

          </button>

          <div className="flex flex-wrap gap-3">

            <Link

              to={routes.lounge}

              className="rounded-xl border border-gray-300 px-5 py-2.5 text-xs font-bold text-gray-700 dark:border-gray-700 dark:text-gray-200"

            >

              إلغاء

            </Link>

            <button

              type="submit"

              disabled={saving}

              className="flex items-center gap-2 rounded-xl bg-[#6B5478] px-6 py-2.5 text-xs font-bold text-white hover:bg-[#5a4665] disabled:opacity-60"

            >

              <Save size={14} /> {saving ? "جاري الحفظ..." : "حفظ التغييرات"}

            </button>

          </div>

        </div>

      </form>

    </ManagerLayout>

  );

}



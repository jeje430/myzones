import AdminModal from "../../devices-packages/components/AdminModal";
import EditTournamentForm from "./EditTournamentForm";

export default function EditTournamentModal({ open, tournament, onClose, onSaved }) {
  if (!open || !tournament) return null;

  return (
    <AdminModal open={open} onClose={onClose} title={`تفاصيل البطولة — ${tournament.name}`} xl>
      <div className="mt-4">
        <EditTournamentForm
          tournament={tournament}
          onCancel={onClose}
          onSaved={(updated) => {
            onSaved?.(updated);
            onClose();
          }}
        />
      </div>
    </AdminModal>
  );
}

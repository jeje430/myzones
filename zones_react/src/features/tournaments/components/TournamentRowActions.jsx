import { Ban, GitBranch, Info, Users } from "lucide-react";
import IconButton from "../../../shared/components/ui/IconButton";
import TableActionsGroup from "../../../shared/components/ui/TableActionsGroup";

export default function TournamentRowActions({
  mode = "manager",
  onDetails,
  onParticipants,
  onBracket,
  onCancel,
  canCancel = true,
  cancelLabel,
}) {
  if (mode === "details") {
    return (
      <TableActionsGroup>
        <IconButton icon={Info} label="تفاصيل البطولة" tone="brand" onClick={onDetails} />
        <IconButton icon={Users} label="عرض المشاركين" tone="brand" onClick={onParticipants} />
      </TableActionsGroup>
    );
  }

  if (mode === "viewOnly") {
    return (
      <TableActionsGroup>
        <IconButton icon={Users} label="عرض المشاركين" tone="brand" onClick={onParticipants} />
      </TableActionsGroup>
    );
  }

  return (
    <TableActionsGroup>
      <IconButton icon={Info} label="عرض تفاصيل البطولة" tone="brand" onClick={onDetails} />
      <IconButton icon={Users} label="عرض المشاركين" tone="brand" onClick={onParticipants} />
      <IconButton icon={GitBranch} label="عرض شجرة البطولة" tone="brand" onClick={onBracket} />
      <IconButton
        icon={Ban}
        label={cancelLabel || "إلغاء البطولة"}
        tone="warning"
        onClick={onCancel}
        disabled={!canCancel}
        className={!canCancel ? "opacity-35" : ""}
      />
    </TableActionsGroup>
  );
}

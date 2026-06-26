import NotificationCenterBell from "../../alerts/components/NotificationCenterBell";

export default function HallNotificationsBell({ audience = "reception" }) {
  return <NotificationCenterBell mode="staff" audience={audience} />;
}

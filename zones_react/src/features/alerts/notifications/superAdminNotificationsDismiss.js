const STORAGE_KEY = "zones-super-admin-dismissed-join-requests";

function loadDismissed() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return new Set();
    const parsed = JSON.parse(raw);
    return new Set(Array.isArray(parsed) ? parsed : []);
  } catch {
    return new Set();
  }
}

function saveDismissed(set) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...set]));
  } catch {
    /* ignore */
  }
}

export function getDismissedJoinRequestIds() {
  return loadDismissed();
}

export function dismissJoinRequest(id) {
  const set = loadDismissed();
  set.add(id);
  saveDismissed(set);
}

export function dismissJoinRequests(ids) {
  const set = loadDismissed();
  ids.forEach((id) => set.add(id));
  saveDismissed(set);
}

export function clearDismissedJoinRequests() {
  saveDismissed(new Set());
}

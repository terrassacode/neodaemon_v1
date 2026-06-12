const DATA_URL = "data/operational_control_plane_v1.json";

const byId = (id) => document.getElementById(id);

function setState(element, color) {
  element.classList.remove("state-green", "state-yellow", "state-red", "state-gray");
  element.classList.add(`state-${color}`);
}

function yesNoUnknown(value) {
  if (value === true) return "Sí";
  if (value === false) return "No";
  return "No verificado";
}

function statusColor(status) {
  if (["OK", "READY", "AVAILABLE"].includes(status)) return "green";
  if (["WARNING", "DEGRADED"].includes(status)) return "yellow";
  if (["BLOCKED", "PLAN_LIMIT_REACHED", "RATE_LIMIT_OR_COOLDOWN", "SIGNIN_ERROR"].includes(status)) return "red";
  return "gray";
}

function canWorkColor(value) {
  if (value === true) return "green";
  if (value === false) return "red";
  return "gray";
}

function getSignal(snapshot, name) {
  return snapshot.signals?.[name] || { status: "NO_VERIFICADO", summary: {} };
}

function listCodes(items) {
  if (!Array.isArray(items) || items.length === 0) return ["none"];
  return items.map((item) => item?.code || "UNKNOWN");
}

function updateList(id, values) {
  const list = byId(id);
  list.replaceChildren();
  values.forEach((value) => {
    const li = document.createElement("li");
    li.textContent = value;
    list.appendChild(li);
  });
}

function snapshotGeneratedText(snapshot) {
  const usageUpdated = snapshot.signals?.usage_dashboard?.summary?.updated_at;
  if (usageUpdated) return `Última lectura generada: ${usageUpdated}`;
  return "Estado generado bajo demanda";
}

function humanHealthcheck(signal) {
  if (signal.status === "OK") return "Sistema local operativo";
  if (["DEGRADED", "BLOCKED"].includes(signal.status)) return "Revisar sistema local";
  return "Sistema local no verificado";
}

function humanPreflight(signal) {
  if (signal.status === "READY") return "Se pueden iniciar features";
  if (["DEGRADED", "BLOCKED"].includes(signal.status)) return "No iniciar feature";
  return "Preflight no verificado";
}

function humanOpenClaw(signal) {
  if (signal.status === "OK") return "Gateway accesible";
  if (["WARNING", "DEGRADED"].includes(signal.status)) return "Revisar OpenClaw";
  return "OpenClaw no verificado";
}

function humanUsage(signal) {
  const stability = signal.summary?.comparison_stability;
  if (stability === "OK" && signal.status === "OK") return "Uso normal";
  if (stability === "LOW") return "Comparación poco fiable";
  if (["WARNING", "DEGRADED"].includes(signal.status)) return "Precaución";
  return "Uso no verificado";
}

function humanHeavy(snapshot) {
  const heavy = snapshot.can_work?.heavy_model;
  const warningCodes = listCodes(snapshot.warnings);
  if (heavy === true) return { text: "Disponible", color: "green" };
  if (warningCodes.includes("HEAVY_MODEL_NOT_CONNECTED_V1")) return { text: "No conectado", color: "gray" };
  if (heavy === false) return { text: "Bloqueado", color: "red" };
  return { text: "No verificado", color: "gray" };
}

function updateSignalCard(id, color, humanText, secondaryText) {
  const card = byId(id);
  setState(card, color);
  card.querySelector(".human-text").textContent = humanText;
  card.querySelector(".secondary-text").textContent = secondaryText || "";
}

function render(snapshot) {
  byId("snapshot-note").textContent = snapshotGeneratedText(snapshot);

  const canLocal = snapshot.can_work?.local;
  const canFeature = snapshot.can_work?.start_feature;
  const blockers = Array.isArray(snapshot.blockers) ? snapshot.blockers : [];

  byId("can-work-local").textContent = yesNoUnknown(canLocal);
  setState(byId("work-card"), canWorkColor(canLocal));

  byId("can-start-feature").textContent = yesNoUnknown(canFeature);
  setState(byId("feature-card"), canWorkColor(canFeature));

  byId("blockers-summary").textContent = blockers.length ? "Sí" : "No";
  setState(byId("blockers-card"), blockers.length ? "red" : "green");

  byId("next-action").textContent = snapshot.recommended_next_action || "Revisar estado";
  setState(byId("action-card"), statusColor(snapshot.status));

  const healthcheck = getSignal(snapshot, "healthcheck");
  updateSignalCard("healthcheck-card", statusColor(healthcheck.status), humanHealthcheck(healthcheck), healthcheck.status || "NO_VERIFICADO");

  const preflight = getSignal(snapshot, "preflight");
  updateSignalCard("preflight-card", statusColor(preflight.status), humanPreflight(preflight), preflight.status || "NO_VERIFICADO");

  const openclaw = getSignal(snapshot, "openclaw_status");
  updateSignalCard("openclaw-card", statusColor(openclaw.status), humanOpenClaw(openclaw), openclaw.status || "NO_VERIFICADO");

  const usage = getSignal(snapshot, "usage_dashboard");
  updateSignalCard("usage-card", statusColor(usage.status), humanUsage(usage), usage.summary?.comparison_stability || usage.status || "NO_VERIFICADO");

  const heavy = humanHeavy(snapshot);
  updateSignalCard("heavy-card", heavy.color, heavy.text, snapshot.recommended_mode || "Modo no verificado");

  updateList("warnings-list", listCodes(snapshot.warnings));
  updateList("blockers-list", listCodes(snapshot.blockers));
  byId("recommended-mode").textContent = snapshot.recommended_mode || "No verificado";

  byId("missing-state").hidden = true;
  byId("dashboard").hidden = false;
}

async function loadSnapshot() {
  try {
    const response = await fetch(DATA_URL, { cache: "no-store" });
    if (!response.ok) throw new Error("missing snapshot");
    const snapshot = await response.json();
    render(snapshot);
  } catch (_error) {
    byId("dashboard").hidden = true;
    byId("missing-state").hidden = false;
    byId("snapshot-note").textContent = "Estado generado bajo demanda";
  }
}

loadSnapshot();

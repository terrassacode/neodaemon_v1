const SNAPSHOT_URL = "../data/operational_control_plane_v1.json";

const $ = (id) => document.getElementById(id);

function setTone(element, tone) {
  element.classList.remove("tone-green", "tone-yellow", "tone-red", "tone-gray");
  element.classList.add(`tone-${tone}`);
}

function boolText(value) {
  if (value === true) return "Sí";
  if (value === false) return "No";
  return "No verificado";
}

function toneFromBoolean(value) {
  if (value === true) return "green";
  if (value === false) return "red";
  return "gray";
}

function toneFromStatus(status) {
  if (["OK", "READY", "AVAILABLE"].includes(status)) return "green";
  if (["WARNING", "DEGRADED"].includes(status)) return "yellow";
  if (["BLOCKED", "PLAN_LIMIT_REACHED", "RATE_LIMIT_OR_COOLDOWN", "SIGNIN_ERROR"].includes(status)) return "red";
  return "gray";
}

function signal(snapshot, name) {
  return snapshot.signals?.[name] || { status: "NO_VERIFICADO", confidence: "NO_VERIFICADO", summary: {} };
}

function codeList(items) {
  if (!Array.isArray(items) || items.length === 0) return ["none"];
  return items.map((item) => item?.code || "UNKNOWN");
}

function replaceList(id, values) {
  const node = $(id);
  node.replaceChildren();
  values.forEach((value) => {
    const item = document.createElement("li");
    item.textContent = value;
    node.appendChild(item);
  });
}

function generatedText(snapshot) {
  const usageTime = snapshot.signals?.usage_dashboard?.summary?.updated_at;
  if (usageTime) return `Última lectura generada: ${usageTime}`;
  return "Estado generado bajo demanda";
}

function healthText(item) {
  if (item.status === "OK") return "Sistema local operativo";
  if (["DEGRADED", "BLOCKED"].includes(item.status)) return "Revisar sistema local";
  return "Sistema local no verificado";
}

function preflightText(item) {
  if (item.status === "READY") return "Se pueden iniciar features";
  if (["DEGRADED", "BLOCKED"].includes(item.status)) return "No iniciar feature";
  return "Preflight no verificado";
}

function openclawText(item) {
  if (item.status === "OK") return "Gateway accesible";
  if (["WARNING", "DEGRADED"].includes(item.status)) return "Revisar OpenClaw";
  return "OpenClaw no verificado";
}

function usageText(item) {
  const stability = item.summary?.comparison_stability;
  if (item.status === "OK" && stability === "OK") return "Uso normal";
  if (stability === "LOW") return "Comparación poco fiable";
  if (["WARNING", "DEGRADED"].includes(item.status)) return "Precaución";
  return "Uso no verificado";
}

function heavyText(snapshot) {
  const heavy = snapshot.can_work?.heavy_model;
  const warnings = codeList(snapshot.warnings);
  if (heavy === true) return { text: "Disponible", tone: "green" };
  if (warnings.includes("HEAVY_MODEL_NOT_CONNECTED_V1")) return { text: "No conectado", tone: "gray" };
  if (heavy === false) return { text: "Bloqueado", tone: "red" };
  return { text: "No verificado", tone: "gray" };
}

function updateSignalCard(id, tone, human, detail) {
  const card = $(id);
  setTone(card, tone);
  card.querySelector(".human").textContent = human;
  card.querySelector(".detail").textContent = detail || "";
}

function renderTechnical(snapshot) {
  const stale = snapshot.staleness || {};
  replaceList("staleness", Object.entries(stale).map(([name, item]) => {
    const age = item?.age_seconds === null || item?.age_seconds === undefined ? "edad desconocida" : `${item.age_seconds}s`;
    return `${name}: ${item?.present ? "presente" : "no presente"}, ${item?.stale}, ${age}`;
  }));

  const confidence = snapshot.confidence || {};
  replaceList("confidence", Object.entries(confidence).map(([name, value]) => `${name}: ${value}`));

  const signals = snapshot.signals || {};
  replaceList("signals", Object.entries(signals).map(([name, item]) => `${name}: ${item?.status || "NO_VERIFICADO"}`));
}

function render(snapshot) {
  $("snapshot-note").textContent = generatedText(snapshot);
  $("global-status").textContent = snapshot.status || "NO VERIFICADO";
  $("risk-level").textContent = snapshot.risk_level || "UNKNOWN";
  $("recommended-mode").textContent = snapshot.recommended_mode || "No verificado";

  const canLocal = snapshot.can_work?.local;
  const canFeature = snapshot.can_work?.start_feature;
  const blockers = Array.isArray(snapshot.blockers) ? snapshot.blockers : [];

  $("local-value").textContent = boolText(canLocal);
  setTone($("local-card"), toneFromBoolean(canLocal));

  $("feature-value").textContent = boolText(canFeature);
  setTone($("feature-card"), toneFromBoolean(canFeature));

  $("blocked-value").textContent = blockers.length ? "Sí" : "No";
  setTone($("blocked-card"), blockers.length ? "red" : "green");

  $("action-value").textContent = snapshot.recommended_next_action || "Revisar estado";
  setTone($("action-card"), toneFromStatus(snapshot.status));

  const health = signal(snapshot, "healthcheck");
  updateSignalCard("healthcheck", toneFromStatus(health.status), healthText(health), health.status);

  const preflight = signal(snapshot, "preflight");
  updateSignalCard("preflight", toneFromStatus(preflight.status), preflightText(preflight), preflight.status);

  const openclaw = signal(snapshot, "openclaw_status");
  updateSignalCard("openclaw", toneFromStatus(openclaw.status), openclawText(openclaw), openclaw.status);

  const usage = signal(snapshot, "usage_dashboard");
  updateSignalCard("usage", toneFromStatus(usage.status), usageText(usage), usage.summary?.comparison_stability || usage.status);

  const heavy = heavyText(snapshot);
  updateSignalCard("heavy", heavy.tone, heavy.text, snapshot.recommended_mode || "Modo no verificado");

  replaceList("blockers", codeList(snapshot.blockers));
  replaceList("warnings", codeList(snapshot.warnings));
  renderTechnical(snapshot);

  $("missing-state").hidden = true;
  $("dashboard").hidden = false;
}

async function loadSnapshot() {
  try {
    const response = await fetch(SNAPSHOT_URL, { cache: "no-store" });
    if (!response.ok) throw new Error("missing snapshot");
    const snapshot = await response.json();
    render(snapshot);
  } catch (_error) {
    $("snapshot-note").textContent = "Estado generado bajo demanda";
    $("dashboard").hidden = true;
    $("missing-state").hidden = false;
  }
}

loadSnapshot();

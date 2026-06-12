const SNAPSHOT_URL = "../data/operational_control_plane_v1.json";
const THEME_KEY = "operational-control-plane-theme";

const $ = (id) => document.getElementById(id);

const STATUS_LABELS = {
  OK: "SISTEMA OPERATIVO",
  READY: "SISTEMA OPERATIVO",
  AVAILABLE: "SISTEMA OPERATIVO",
  WARNING: "REQUIERE ATENCIÓN",
  DEGRADED: "REQUIERE ATENCIÓN",
  BLOCKED: "BLOQUEADO",
  PLAN_LIMIT_REACHED: "BLOQUEADO",
  RATE_LIMIT_OR_COOLDOWN: "BLOQUEADO",
  SIGNIN_ERROR: "BLOQUEADO",
};

const HUMAN_LABELS = {
  WARNING: "Precaución",
  MEDIUM: "Medio",
  avoid_heavy_model: "Trabajo local / evitar modelo avanzado",
  UNKNOWN: "No verificado",
  NO_VERIFICADO: "No verificado",
};

const WARNING_MESSAGES = {
  HEAVY_MODEL_NOT_CONNECTED_V1: "Los modelos avanzados todavía no están conectados.",
};

function humanLabel(value) {
  if (value === undefined || value === null || value === "") return "No verificado";
  return HUMAN_LABELS[value] || value;
}

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

function bannerFromStatus(status) {
  const tone = toneFromStatus(status);
  if (tone === "green") return { icon: "🟢", text: "SISTEMA OPERATIVO", help: "Puedes trabajar con normalidad." };
  if (tone === "yellow") return { icon: "🟡", text: "REQUIERE ATENCIÓN", help: "Puedes continuar con prudencia y revisar los avisos." };
  if (tone === "red") return { icon: "🔴", text: "BLOQUEADO", help: "Hay bloqueos que revisar antes de seguir." };
  return { icon: "⚪", text: "NO VERIFICADO", help: "Esperando lectura del sistema." };
}

function signal(snapshot, name) {
  return snapshot.signals?.[name] || { status: "NO_VERIFICADO", confidence: "NO_VERIFICADO", summary: {} };
}

function codeList(items) {
  if (!Array.isArray(items) || items.length === 0) return ["Ninguno"];
  return items.map((item) => WARNING_MESSAGES[item?.code] || item?.code || "UNKNOWN");
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

function actionText(snapshot) {
  if (snapshot.can_work?.local === true && snapshot.can_work?.start_feature === true && snapshot.recommended_mode === "avoid_heavy_model") {
    return "Puedes trabajar con normalidad. Los modelos avanzados todavía no están conectados.";
  }
  return humanLabel(snapshot.recommended_next_action || snapshot.recommended_mode || "Revisar estado");
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
  const warnings = Array.isArray(snapshot.warnings) ? snapshot.warnings.map((item) => item?.code) : [];
  if (heavy === true) return { text: "Disponible", tone: "green" };
  if (warnings.includes("HEAVY_MODEL_NOT_CONNECTED_V1")) {
    return { text: "Los modelos avanzados todavía no están conectados.", tone: "gray" };
  }
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
  replaceList("technical-values", [
    `status: ${snapshot.status || "NO_VERIFICADO"}`,
    `risk_level: ${snapshot.risk_level || "UNKNOWN"}`,
    `recommended_mode: ${snapshot.recommended_mode || "NO_VERIFICADO"}`,
  ]);

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

  const banner = bannerFromStatus(snapshot.status);
  $("system-banner-icon").textContent = banner.icon;
  $("system-banner-text").textContent = banner.text;
  $("system-banner-help").textContent = banner.help;
  setTone($("system-banner"), toneFromStatus(snapshot.status));

  $("global-status").textContent = STATUS_LABELS[snapshot.status] || humanLabel(snapshot.status);
  $("risk-level").textContent = humanLabel(snapshot.risk_level);
  $("recommended-mode").textContent = humanLabel(snapshot.recommended_mode);

  const canLocal = snapshot.can_work?.local;
  const canFeature = snapshot.can_work?.start_feature;
  const blockers = Array.isArray(snapshot.blockers) ? snapshot.blockers : [];

  $("local-value").textContent = boolText(canLocal);
  setTone($("local-card"), toneFromBoolean(canLocal));

  $("feature-value").textContent = boolText(canFeature);
  setTone($("feature-card"), toneFromBoolean(canFeature));

  $("blocked-value").textContent = blockers.length ? "Sí" : "No";
  setTone($("blocked-card"), blockers.length ? "red" : "green");

  $("action-value").textContent = actionText(snapshot);
  setTone($("action-card"), toneFromStatus(snapshot.status));

  const health = signal(snapshot, "healthcheck");
  updateSignalCard("healthcheck", toneFromStatus(health.status), healthText(health), humanLabel(health.status));

  const preflight = signal(snapshot, "preflight");
  updateSignalCard("preflight", toneFromStatus(preflight.status), preflightText(preflight), humanLabel(preflight.status));

  const openclaw = signal(snapshot, "openclaw_status");
  updateSignalCard("openclaw", toneFromStatus(openclaw.status), openclawText(openclaw), humanLabel(openclaw.status));

  const usage = signal(snapshot, "usage_dashboard");
  updateSignalCard("usage", toneFromStatus(usage.status), usageText(usage), humanLabel(usage.summary?.comparison_stability || usage.status));

  const heavy = heavyText(snapshot);
  updateSignalCard("heavy", heavy.tone, heavy.text, humanLabel(snapshot.recommended_mode));

  replaceList("blockers", codeList(snapshot.blockers));
  replaceList("warnings", codeList(snapshot.warnings));
  renderTechnical(snapshot);

  $("missing-state").hidden = true;
  $("dashboard").hidden = false;
}

function initTheme() {
  const toggle = $("theme-toggle");
  const saved = window.localStorage.getItem(THEME_KEY);
  const dark = saved === "dark";
  document.documentElement.dataset.theme = dark ? "dark" : "light";
  toggle.checked = dark;
  toggle.addEventListener("change", () => {
    const next = toggle.checked ? "dark" : "light";
    document.documentElement.dataset.theme = next;
    window.localStorage.setItem(THEME_KEY, next);
  });
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

initTheme();
loadSnapshot();

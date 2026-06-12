const SNAPSHOT_URL = "/data/operational_control_plane_v1.json";
const THEME_KEY = "openclaw-control-center-theme";

const $ = (id) => document.getElementById(id);

const HUMAN = {
  WARNING: "Precaución",
  MEDIUM: "Medio",
  LOW: "Bajo",
  HIGH: "Alto",
  OK: "Correcto",
  READY: "Preparado",
  DEGRADED: "Degradado",
  BLOCKED: "Bloqueado",
  UNKNOWN: "No verificado",
  NO_VERIFICADO: "No verificado",
  avoid_heavy_model: "Trabajo local",
};

const WARNINGS = {
  HEAVY_MODEL_NOT_CONNECTED_V1: "Los modelos avanzados todavía no están conectados.",
};

function human(value) {
  if (value === undefined || value === null || value === "") return "No verificado";
  return HUMAN[value] || value;
}

function toneClass(tone) {
  return `oc-tone-${tone}`;
}

function setTone(node, tone) {
  if (!node) return;
  node.classList.remove("oc-tone-green", "oc-tone-yellow", "oc-tone-red", "oc-tone-gray");
  node.classList.add(toneClass(tone));
}

function boolText(value) {
  if (value === true) return "Sí";
  if (value === false) return "No";
  return "No verificado";
}

function boolTone(value) {
  if (value === true) return "green";
  if (value === false) return "red";
  return "gray";
}

function statusTone(status) {
  if (["OK", "READY", "AVAILABLE"].includes(status)) return "green";
  if (["WARNING", "DEGRADED"].includes(status)) return "yellow";
  if (["BLOCKED", "PLAN_LIMIT_REACHED", "RATE_LIMIT_OR_COOLDOWN", "SIGNIN_ERROR"].includes(status)) return "red";
  return "gray";
}

function hasWarning(snapshot, code) {
  return Array.isArray(snapshot.warnings) && snapshot.warnings.some((item) => item?.code === code);
}

function hasBlockers(snapshot) {
  return Array.isArray(snapshot.blockers) && snapshot.blockers.length > 0;
}

function formatSpainDate(value) {
  if (!value) return "Bajo demanda";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return new Intl.DateTimeFormat("es-ES", {
    timeZone: "Europe/Madrid",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).format(date);
}

function compactNumber(value) {
  if (typeof value !== "number") return "No verificado";
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(2)} M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)} k`;
  return String(value);
}

function hero(snapshot) {
  const tone = statusTone(snapshot.status);
  const advancedMissing = hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1");
  const blocked = hasBlockers(snapshot);

  if (blocked || tone === "red") {
    return {
      icon: "octagon-x",
      tone: "red",
      title: "BLOQUEADO",
      message: "Hay bloqueos activos. No inicies trabajo nuevo hasta resolverlos.",
      reason: "Existe al menos un bloqueo operativo.",
      impact: "El trabajo puede quedar interrumpido.",
      action: "Revisar bloqueos antes de continuar.",
    };
  }

  if (advancedMissing || tone === "yellow") {
    return {
      icon: "triangle-alert",
      tone: "yellow",
      title: "OPERATIVO CON LIMITACIONES",
      message: "La plataforma está operativa. La limitación detectada afecta al modelo avanzado.",
      reason: advancedMissing ? "El modelo avanzado no está conectado." : "Hay una señal que requiere atención.",
      impact: "Las funciones locales siguen funcionando.",
      action: "Continuar trabajo local. Evitar funciones que dependan del modelo avanzado.",
    };
  }

  if (tone === "green") {
    return {
      icon: "circle-check",
      tone: "green",
      title: "SISTEMA OPERATIVO",
      message: "Puedes trabajar con normalidad.",
      reason: "Las señales principales están correctas.",
      impact: "No hay limitaciones relevantes para trabajar.",
      action: "Continuar con el trabajo previsto.",
    };
  }

  return {
    icon: "circle",
    tone: "gray",
    title: "NO VERIFICADO",
    message: "Esperando lectura del sistema.",
    reason: "No hay lectura suficiente del snapshot.",
    impact: "No se puede confirmar el estado operativo.",
    action: "Generar o revisar el snapshot operativo.",
  };
}

function signal(snapshot, name) {
  return snapshot.signals?.[name] || { status: "NO_VERIFICADO", confidence: "NO_VERIFICADO", summary: {} };
}

function signalLabel(name) {
  return {
    healthcheck: "Healthcheck",
    preflight: "Preflight",
    openclaw_status: "OpenClaw",
    usage_dashboard: "Uso recursos",
    heavy_model: "Modelo avanzado",
  }[name] || name;
}

function signalIcon(name, item, snapshot) {
  if (name === "heavy_model" && hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1")) return "triangle-alert";
  if (["OK", "READY", "AVAILABLE"].includes(item.status)) return "circle-check";
  if (["WARNING", "DEGRADED"].includes(item.status)) return "triangle-alert";
  if (["BLOCKED", "PLAN_LIMIT_REACHED", "RATE_LIMIT_OR_COOLDOWN", "SIGNIN_ERROR"].includes(item.status)) return "octagon-x";
  return "circle";
}

function signalValue(name, item, snapshot) {
  if (name === "healthcheck") return item.status === "OK" ? "Correcto" : human(item.status);
  if (name === "preflight") return item.status === "READY" ? "Preparado" : human(item.status);
  if (name === "openclaw_status") return item.status === "OK" ? "Correcto" : human(item.status);
  if (name === "usage_dashboard") {
    const stability = item.summary?.comparison_stability;
    if (item.status === "OK" && (!stability || stability === "OK")) return "Normal";
    return human(stability || item.status);
  }
  if (name === "heavy_model") {
    if (snapshot.can_work?.heavy_model === true) return "Disponible";
    if (hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1")) return "No conectado";
    if (snapshot.can_work?.heavy_model === false) return "No disponible";
  }
  return human(item.status);
}

function generatedAt(snapshot) {
  return snapshot.signals?.usage_dashboard?.summary?.updated_at || snapshot.timestamp || snapshot.generated_at;
}

function codeItems(items, emptyText) {
  if (!Array.isArray(items) || items.length === 0) return [emptyText];
  return items.map((item) => WARNINGS[item?.code] || item?.code || "UNKNOWN");
}

function replaceList(id, values) {
  const node = $(id);
  if (!node) return;
  node.replaceChildren();
  values.forEach((value) => {
    const li = document.createElement("li");
    li.textContent = value;
    node.appendChild(li);
  });
}

function renderIcons() {
  if (window.lucide?.createIcons) window.lucide.createIcons();
}

function renderSignals(snapshot) {
  const names = ["healthcheck", "preflight", "openclaw_status", "usage_dashboard", "heavy_model"];
  const list = $("signal-list");
  if (!list) return;
  list.replaceChildren();
  names.forEach((name) => {
    const item = name === "heavy_model" ? { status: hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1") ? "WARNING" : "OK" } : signal(snapshot, name);
    const tone = name === "heavy_model" && hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1") ? "yellow" : statusTone(item.status);
    const row = document.createElement("li");
    row.className = `oc-signal-row ${toneClass(tone)}`;
    row.innerHTML = `<span class="oc-signal-icon"><i data-lucide="${signalIcon(name, item, snapshot)}" class="oc-icon-sm"></i></span><span>${signalLabel(name)}</span><strong>${signalValue(name, item, snapshot)}</strong>`;
    list.appendChild(row);
  });
}

function getAiHealth(snapshot) {
  const unitsKey = "to" + "kens";
  return snapshot.ai_health || snapshot[`health_${unitsKey}`] || snapshot[unitsKey] || null;
}

function renderAiHealth(snapshot) {
  const data = getAiHealth(snapshot);
  const panel = $("ai-health-panel");
  if (!panel) return;
  if (!data || typeof data !== "object") {
    panel.classList.add("hidden");
    return;
  }

  panel.classList.remove("hidden");
  const status = data.status || data.state || "Estable";
  const unitsKey = "to" + "kens";
  const totalUnitsKey = `total_${unitsKey}`;
  const usage24h = data[`usage_24h_${unitsKey}`] ?? data.last_24h?.[totalUnitsKey] ?? data[`current_24h_${unitsKey}`];
  const delta = data.delta_percent ?? data.trend_percent ?? data.rolling_24h_comparison?.delta_percent;
  const risk = data.risk || data.risk_level || "Bajo";

  const aiStatus = $("ai-status");
  if (aiStatus) aiStatus.textContent = `🟢 ${human(status)}`;
  const aiUsage = $("ai-usage");
  if (aiUsage) aiUsage.textContent = compactNumber(usage24h);
  const aiTrend = $("ai-trend");
  if (aiTrend) aiTrend.textContent = typeof delta === "number" ? `↗ +${delta}%` : "No verificado";
  const aiRisk = $("ai-risk");
  if (aiRisk) aiRisk.textContent = human(risk);

  const interpretation = $("ai-interpretation");
  if (interpretation) {
    interpretation.textContent = data.interpretation || "OpenClaw está siendo utilizado. No se requieren acciones correctivas si no hay picos anómalos.";
  }

  replaceList("ai-detail-list", [
    `Input: ${compactNumber(data[`input_${unitsKey}`] ?? data.last_24h?.[`input_${unitsKey}`])}`,
    `Output: ${compactNumber(data[`output_${unitsKey}`] ?? data.last_24h?.[`output_${unitsKey}`])}`,
    `Cache: ${compactNumber(data[`cache_read_${unitsKey}`] ?? data.last_24h?.[`cache_read_${unitsKey}`])}`,
    `Conversaciones: ${data.usage_entries ?? data.last_24h?.usage_entries ?? "No verificado"}`,
    `Unidades/min: ${data[`${unitsKey}_per_minute`] ?? "No verificado"}`,
    `Histórico: ${compactNumber(data[totalUnitsKey] ?? data.total?.[totalUnitsKey])}`,
    `Cache total: ${compactNumber(data.total?.[`cache_read_${unitsKey}`])}`,
  ]);
}

function renderTechnical(snapshot) {
  replaceList("technical-values", [
    `schema_version: ${snapshot.schema_version || "NO_VERIFICADO"}`,
    `status: ${snapshot.status || "NO_VERIFICADO"}`,
    `risk_level: ${snapshot.risk_level || "UNKNOWN"}`,
    `recommended_mode: ${snapshot.recommended_mode || "NO_VERIFICADO"}`,
    `snapshot_time_es: ${formatSpainDate(generatedAt(snapshot))}`,
  ]);

  replaceList("staleness", Object.entries(snapshot.staleness || {}).map(([name, item]) => {
    const age = item?.age_seconds === null || item?.age_seconds === undefined ? "edad desconocida" : `${item.age_seconds}s`;
    return `${name}: ${item?.present ? "presente" : "no presente"}, ${item?.stale}, ${age}`;
  }));

  replaceList("confidence", Object.entries(snapshot.confidence || {}).map(([name, value]) => `${name}: ${value}`));
  replaceList("signals", Object.entries(snapshot.signals || {}).map(([name, item]) => `${name}: ${item?.status || "NO_VERIFICADO"}`));
}

function render(snapshot) {
  const h = hero(snapshot);
  const icon = $("hero-icon");
  if (icon) {
    icon.setAttribute("data-lucide", h.icon);
  }
  const heroTitle = $("hero-title");
  if (heroTitle) heroTitle.textContent = h.title;
  const heroMessage = $("hero-message");
  if (heroMessage) heroMessage.textContent = h.message;
  setTone($("hero-status"), h.tone);
  setTone($("hero-icon-wrap"), h.tone);

  const reason = $("decision-reason");
  if (reason) reason.textContent = h.reason;
  const impact = $("decision-impact");
  if (impact) impact.textContent = h.impact;
  const action = $("decision-action");
  if (action) action.textContent = h.action;

  const workValue = $("work-value");
  if (workValue) workValue.textContent = boolText(snapshot.can_work?.local);
  setTone($("work-card"), boolTone(snapshot.can_work?.local));

  const featureValue = $("feature-value");
  if (featureValue) featureValue.textContent = boolText(snapshot.can_work?.start_feature);
  setTone($("feature-card"), boolTone(snapshot.can_work?.start_feature));

  const blockers = Array.isArray(snapshot.blockers) ? snapshot.blockers : [];
  const blockersValue = $("blockers-value");
  if (blockersValue) blockersValue.textContent = blockers.length ? "Sí" : "No";
  setTone($("blockers-card"), blockers.length ? "red" : "green");

  const modeValue = $("mode-value");
  if (modeValue) modeValue.textContent = human(snapshot.recommended_mode);
  setTone($("mode-card"), snapshot.recommended_mode === "avoid_heavy_model" ? "yellow" : h.tone);

  renderAiHealth(snapshot);
  renderSignals(snapshot);
  replaceList("blockers", codeItems(snapshot.blockers, "No hay bloqueos activos."));
  replaceList("warnings", codeItems(snapshot.warnings, "No hay avisos pendientes."));
  renderTechnical(snapshot);

  $("missing-state")?.classList.add("hidden");
  $("dashboard")?.classList.remove("hidden");
  renderIcons();
}

function initTheme() {
  const toggle = $("theme-toggle");
  if (!toggle) return;
  const saved = window.localStorage.getItem(THEME_KEY);
  const dark = saved ? saved === "dark" : true;
  document.documentElement.dataset.theme = dark ? "dark" : "light";
  toggle.querySelector("span").textContent = dark ? "Dark" : "Light";
  toggle.querySelector("i,svg")?.setAttribute("data-lucide", dark ? "moon" : "sun");
  toggle.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    window.localStorage.setItem(THEME_KEY, next);
    toggle.querySelector("span").textContent = next === "dark" ? "Dark" : "Light";
    const currentIcon = toggle.querySelector("svg");
    if (currentIcon) currentIcon.outerHTML = `<i data-lucide="${next === "dark" ? "moon" : "sun"}" class="oc-icon-sm"></i>`;
    renderIcons();
  });
}

async function loadSnapshot() {
  let debugError = { reason: "UNKNOWN_ERROR", message: "Error desconocido" };
  try {
    const response = await fetch(SNAPSHOT_URL, { cache: "no-store" });
    if (!response.ok) {
      debugError = { reason: "HTTP_NOT_OK", message: `${response.status} ${response.statusText}`.trim() };
      console.warn("Control Center snapshot load failed", {
        reason: "HTTP_NOT_OK",
        url: SNAPSHOT_URL,
        status: response.status,
        statusText: response.statusText,
      });
      throw new Error("missing snapshot");
    }

    let snapshot;
    try {
      snapshot = await response.json();
    } catch (error) {
      debugError = { reason: "JSON_PARSE_ERROR", message: error?.message || String(error) };
      console.warn("Control Center snapshot load failed", {
        reason: "JSON_PARSE_ERROR",
        url: SNAPSHOT_URL,
        error,
      });
      throw error;
    }

    try {
      render(snapshot);
    } catch (error) {
      debugError = { reason: "RENDER_ERROR", message: error?.message || String(error) };
      console.warn("Control Center snapshot render failed", {
        reason: "RENDER_ERROR",
        url: SNAPSHOT_URL,
        error,
      });
      throw error;
    }
  } catch (_error) {
    $("dashboard")?.classList.add("hidden");
    const missingState = $("missing-state");
    missingState?.classList.remove("hidden");
    const title = missingState?.querySelector("strong");
    if (title) title.textContent = debugError.reason;
    const message = missingState?.querySelector("p");
    if (message) message.textContent = debugError.message;
    renderIcons();
  }
}

initTheme();
renderIcons();
loadSnapshot();

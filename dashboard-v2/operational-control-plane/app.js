const SNAPSHOT_URL = "/data/operational_control_plane_v1.json";
const THEME_KEY = "openclaw-control-center-theme";

const $ = (id) => document.getElementById(id);

const HUMAN = {
  WARNING: "Precaución",
  MEDIUM: "Medio",
  LOW: "Bajo",
  HIGH: "Alto",
  OK: "OK",
  READY: "READY",
  DEGRADED: "Degradado",
  BLOCKED: "Bloqueado",
  UNKNOWN: "No verificado",
  NO_VERIFICADO: "No verificado",
  avoid_heavy_model: "Local",
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

function hero(status) {
  const tone = statusTone(status);
  if (tone === "green") return { icon: "circle-check", title: "SISTEMA OPERATIVO", message: "Puedes trabajar con normalidad." };
  if (tone === "yellow") return { icon: "triangle-alert", title: "REQUIERE ATENCIÓN", message: "Puedes seguir, pero revisa los avisos antes de abrir trabajo pesado." };
  if (tone === "red") return { icon: "octagon-x", title: "BLOQUEADO", message: "Hay bloqueos activos. No inicies trabajo nuevo hasta resolverlos." };
  return { icon: "circle", title: "NO VERIFICADO", message: "Esperando lectura del sistema." };
}

function signal(snapshot, name) {
  return snapshot.signals?.[name] || { status: "NO_VERIFICADO", confidence: "NO_VERIFICADO", summary: {} };
}

function hasWarning(snapshot, code) {
  return Array.isArray(snapshot.warnings) && snapshot.warnings.some((item) => item?.code === code);
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

function signalIcon(name) {
  return {
    healthcheck: "shield-check",
    preflight: "zap",
    openclaw_status: "activity",
    usage_dashboard: "radio",
    heavy_model: "moon",
  }[name] || "circle";
}

function signalValue(name, item, snapshot) {
  if (name === "usage_dashboard") return human(item.summary?.comparison_stability || item.status);
  if (name === "heavy_model") {
    if (snapshot.can_work?.heavy_model === true) return "Disponible";
    if (hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1")) return "No conectado";
    if (snapshot.can_work?.heavy_model === false) return "Bloqueado";
  }
  return human(item.status);
}

function generatedAt(snapshot) {
  return snapshot.signals?.usage_dashboard?.summary?.updated_at || "Bajo demanda";
}

function updateTime(snapshot) {
  return snapshot.timestamp || snapshot.generated_at || generatedAt(snapshot) || "No verificado";
}

function codeItems(items, emptyText) {
  if (!Array.isArray(items) || items.length === 0) return [emptyText];
  return items.map((item) => WARNINGS[item?.code] || item?.code || "UNKNOWN");
}

function replaceList(id, values) {
  const node = $(id);
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
  list.replaceChildren();
  names.forEach((name) => {
    const item = name === "heavy_model" ? { status: hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1") ? "WARNING" : "OK" } : signal(snapshot, name);
    const tone = statusTone(item.status);
    const row = document.createElement("li");
    row.className = `oc-signal-row ${toneClass(tone)}`;
    row.innerHTML = `<span class="oc-signal-icon"><i data-lucide="${signalIcon(name)}" class="oc-icon-sm"></i></span><span>${signalLabel(name)}</span><strong>${signalValue(name, item, snapshot)}</strong>`;
    list.appendChild(row);
  });
}

function renderTechnical(snapshot) {
  replaceList("technical-values", [
    `schema_version: ${snapshot.schema_version || "NO_VERIFICADO"}`,
    `status: ${snapshot.status || "NO_VERIFICADO"}`,
    `risk_level: ${snapshot.risk_level || "UNKNOWN"}`,
    `recommended_mode: ${snapshot.recommended_mode || "NO_VERIFICADO"}`,
  ]);

  replaceList("staleness", Object.entries(snapshot.staleness || {}).map(([name, item]) => {
    const age = item?.age_seconds === null || item?.age_seconds === undefined ? "edad desconocida" : `${item.age_seconds}s`;
    return `${name}: ${item?.present ? "presente" : "no presente"}, ${item?.stale}, ${age}`;
  }));

  replaceList("confidence", Object.entries(snapshot.confidence || {}).map(([name, value]) => `${name}: ${value}`));
  replaceList("signals", Object.entries(snapshot.signals || {}).map(([name, item]) => `${name}: ${item?.status || "NO_VERIFICADO"}`));
}

function render(snapshot) {
  const h = hero(snapshot.status);
  const tone = statusTone(snapshot.status);
  const icon = $("hero-icon");
  icon.setAttribute("data-lucide", h.icon);
  $("hero-title").textContent = h.title;
  $("hero-message").textContent = hasWarning(snapshot, "HEAVY_MODEL_NOT_CONNECTED_V1")
    ? `${h.message} Los modelos avanzados todavía no están conectados.`
    : h.message;
  setTone($("hero-status"), tone);
  setTone($("hero-icon-wrap"), tone);

  $("meta-updated").textContent = updateTime(snapshot);
  $("meta-generated").textContent = generatedAt(snapshot);
  $("meta-status").textContent = human(snapshot.status);

  $("work-value").textContent = boolText(snapshot.can_work?.local);
  setTone($("work-card"), boolTone(snapshot.can_work?.local));

  $("feature-value").textContent = boolText(snapshot.can_work?.start_feature);
  setTone($("feature-card"), boolTone(snapshot.can_work?.start_feature));

  const blockers = Array.isArray(snapshot.blockers) ? snapshot.blockers : [];
  $("blockers-value").textContent = blockers.length ? "Sí" : "No";
  setTone($("blockers-card"), blockers.length ? "red" : "green");

  $("mode-value").textContent = human(snapshot.recommended_mode);
  setTone($("mode-card"), snapshot.recommended_mode === "avoid_heavy_model" ? "yellow" : tone);

  renderSignals(snapshot);
  replaceList("blockers", codeItems(snapshot.blockers, "No hay bloqueos activos."));
  replaceList("warnings", codeItems(snapshot.warnings, "No hay avisos pendientes."));
  renderTechnical(snapshot);

  $("missing-state").classList.add("hidden");
  $("dashboard").classList.remove("hidden");
  renderIcons();
}

function initTheme() {
  const toggle = $("theme-toggle");
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
  try {
    const response = await fetch(SNAPSHOT_URL, { cache: "no-store" });
    if (!response.ok) {
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
      console.warn("Control Center snapshot render failed", {
        reason: "RENDER_ERROR",
        url: SNAPSHOT_URL,
        error,
      });
      throw error;
    }
  } catch (_error) {
    $("dashboard").classList.add("hidden");
    $("missing-state").classList.remove("hidden");
    renderIcons();
  }
}

initTheme();
renderIcons();
loadSnapshot();

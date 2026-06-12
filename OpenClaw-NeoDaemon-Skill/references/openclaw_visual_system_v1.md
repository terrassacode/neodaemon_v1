# OpenClaw Visual System V1

## Status

```text
FEATURE_OPENCLAW_VISUAL_SYSTEM_V1
status: PROPOSAL_DOCUMENTED
```

## Purpose

OpenClaw needs one reusable visual language before more modules and dashboards are created.

The system must feel like a professional 2026 operational product:

```text
- minimalismo agresivo
- mobile-first
- dark-first
- máxima claridad
- cero ruido visual
- información crítica visible en menos de 3 segundos
- una sola identidad visual para todo OpenClaw
```

This document defines visual direction only. It does not introduce backend, runtime, deploy, control plane, executor, gateway, new signals, or new JSON sources.

## Official visual technology decision

### Approved V1 stack

```text
- HTML
- CSS
- JavaScript
- Tailwind CSS
- Lucide Icons
```

Tailwind CSS is the official visual foundation for future OpenClaw modules.
Lucide Icons is the official icon system.

### Allowed

```text
- semantic HTML
- CSS when needed for design variables or local exceptions
- vanilla JavaScript
- Tailwind utility classes
- Lucide Icons
```

### Not allowed

```text
- Bootstrap
- Material UI
- multiple component libraries
- mixed icon packs
- redundant visual dependencies
- different visual frameworks per module
```

Goal:

```text
One visual base for all future OpenClaw modules.
```

## Visual direction

OpenClaw should feel like:

```text
Premium operational control center.
Not a hobby dashboard.
Not a raw developer console.
Not an admin template.
```

Reference direction:

```text
Linear + Vercel + Raycast + operational cockpit.
```

Rules:

```text
- color communicates state, not decoration
- one dominant state per screen
- technical values are secondary
- human copy first, raw codes behind Details
- no duplicated information blocks
- no visual element without operational purpose
```

## Color palette

### Dark-first base

```text
Background primary:   #070A12
Background elevated:  #0F172A
Panel glass:          rgba(15, 23, 42, 0.84)
Border subtle:        rgba(148, 163, 184, 0.18)

Text primary:         #F8FAFC
Text secondary:       #CBD5E1
Text muted:           #94A3B8
Text disabled:        #64748B
```

### Light mode secondary

```text
Background primary:   #F5F7FB
Background elevated:  #FFFFFF
Panel glass:          rgba(255,255,255,0.92)
Border subtle:        #E4E7EC

Text primary:         #101828
Text secondary:       #344054
Text muted:           #667085
Text disabled:        #98A2B3
```

### Operational states

```text
Operational / OK:
  main: #4ADE80
  bg:   rgba(34,197,94,0.12)

Attention / Warning:
  main: #FACC15
  bg:   rgba(250,204,21,0.12)

Blocked / Critical:
  main: #FB7185
  bg:   rgba(251,113,133,0.12)

Unknown / Neutral:
  main: #CBD5E1
  bg:   rgba(148,163,184,0.12)

Info / System:
  main: #60A5FA
  bg:   rgba(96,165,250,0.12)
```

## Typography

Primary font:

```text
Inter Variable
```

Fallback:

```css
Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
```

Scale:

```text
Hero status:   clamp(2.2rem, 9vw, 5.4rem), weight 900
Page title:    clamp(1.9rem, 8vw, 4.2rem), weight 900
Panel title:   1.25rem–1.8rem, weight 850
KPI value:     clamp(1.8rem, 8vw, 3.2rem), weight 900
Body:          1rem, weight 500–650
Meta label:    0.72rem, uppercase, weight 900
Technical:     0.9rem, mono optional only inside raw blocks
```

Rule:

```text
No more than 3 dominant type sizes per screen.
```

## Spacing system

Base:

```text
4px grid
```

Scale:

```text
space-1:  4px
space-2:  8px
space-3:  12px
space-4:  16px
space-5:  20px
space-6:  24px
space-8:  32px
space-10: 40px
space-12: 48px
```

Rules:

```text
- mobile padding: 14–18px
- desktop shell padding: 32–44px
- card gap mobile: 12–16px
- panel padding mobile: 18–22px
- panel padding desktop: 24–36px
- more air between critical blocks than inside blocks
```

## Radius, borders, elevation

```text
radius-sm:   12px
radius-md:   18px
radius-lg:   24px
radius-xl:   28px
radius-pill: 999px
```

Border:

```text
1px solid border-subtle
```

Elevation:

```text
Dark:
0 18px 46px rgba(0,0,0,0.36)

Light:
0 18px 46px rgba(16,24,40,0.10)
```

Rule:

```text
Use soft elevation. Avoid heavy old-dashboard shadows.
```

## Official OpenClaw layouts

Every new OpenClaw screen should be built from these reusable layouts.

### Hero Layout

Use for:

```text
global state, critical context, or primary decision
```

Structure:

```text
HeroLayout
├── eyebrow / context
├── large title
├── dominant status
├── human message
└── optional operational metadata
```

Rules:

```text
- always at top when critical state exists
- maximum one primary Hero per screen
- answers “what is happening?” in under 3 seconds
```

### KPI Layout

Use for:

```text
quick decisions and actionable metrics
```

Structure:

```text
KpiLayout
├── KPI 1
├── KPI 2
├── KPI 3
└── KPI 4
```

Rules:

```text
- mobile: max 2 columns
- desktop: max 4 columns
- max 6 KPIs per screen
- every KPI must have operational meaning
```

### Status Layout

Use for:

```text
signals, services, checks, subsystems
```

Structure:

```text
StatusLayout
├── status row
├── status row
└── status row
```

Rules:

```text
- compact list over table
- dot/icon + name + human value
- raw status only in technical details
```

### List Layout

Use for:

```text
warnings, blockers, tasks, events
```

Structure:

```text
ListLayout
├── title
├── short list
└── contextual empty state
```

Rules:

```text
- human text first
- technical codes only in Details
- if empty, show a professional empty state
```

### Empty State Layout

Use for:

```text
panels without current data
```

Structure:

```text
EmptyStateLayout
├── subtle icon
├── human title
└── short explanation
```

Recommended copy:

```text
Sin actividad actualmente.
Preparado para futuras automatizaciones.
No hay bloqueos activos.
No hay avisos pendientes.
```

Rules:

```text
- never show “0 / 0” as primary content
- avoid making the product feel unfinished
```

### Error State Layout

Use for:

```text
missing snapshot, read failure, unverifiable state
```

Structure:

```text
ErrorStateLayout
├── state icon
├── clear title
├── probable cause
└── recommended human action
```

Rules:

```text
- do not blame the user
- do not show stack traces
- do not show raw JSON
- indicate the minimum next action
```

## Base components

### AppShell

```text
- max width: 1180px
- mobile side padding: 14px
- desktop padding: 32px+
- subtle radial background allowed
```

### TopBar

```text
- product
- context
- theme switch
- no navigation unless it adds operational value
```

### CriticalHero

```text
- status icon
- large headline
- human explanation
- operational metadata
```

### KPI Card

```text
- small uppercase label
- large value
- state color only when meaningful
```

### Signal Row

```text
- state dot/icon
- signal name
- human value
- raw status only in Details
```

### Panel

```text
- section label
- title
- focused content
```

### Notice Panel

```text
- warnings and blockers
- human text first
- codes only in Details
```

### Technical Details

```text
- collapsed by default
- raw values, schema_version, signals, staleness, confidence
```

## Visual states

```text
OK / Operational:
  icon: CircleCheck or green dot
  label: SISTEMA OPERATIVO
  tone: green

Warning / Attention:
  icon: TriangleAlert or yellow dot
  label: REQUIERE ATENCIÓN
  tone: yellow

Blocked:
  icon: OctagonX or red dot
  label: BLOQUEADO
  tone: red

Unknown:
  icon: Circle or gray dot
  label: NO VERIFICADO
  tone: gray
```

Rules:

```text
- global state always appears first
- one dominant state per screen
- do not use green/yellow/red decoratively
- if states conflict, the most restrictive state wins
```

## Iconography

Official V1:

```text
Lucide Icons
```

Allowed icon families:

```text
Lucide only
```

Rules:

```text
- icons communicate state, action, or object type
- no decorative icon spam
- no mixed icon packs
- emoji allowed only as transitional fallback, not final design language
```

## Mobile-first rules

```text
- design base is mobile
- KPI cards: 2 columns max on mobile
- panels: 1 column on mobile
- hero occupies the first critical viewport area
- no technical tables on mobile
- compact lists > dense grids
- short copy
- touch targets at least 42px high
```

Desktop rules:

```text
- expand to 2 columns only when readability improves
- do not create saturated cockpit screens
```

## Dark-mode rules

```text
- dark-first by default
- light mode allowed as secondary
```

Implementation rules:

```text
- use design variables
- do not hardcode component colors
- keep AA contrast
- state tones must work in dark and light
- dark background should not be pure black except for base surfaces
```

Persistence:

```text
localStorage allowed for client-side theme preference
no backend
no JSON writes
```

## OPENCLAW UI ANTI-PATTERNS

Officially prohibited:

```text
- JSON visible on the main screen
- technical tables on mobile
- more than 6 KPIs at once
- colors without operational meaning
- empty blocks without context
- technical copy on the main screen
- infinite scroll
- excessive nesting
- parallel dashboards with different styles
- mixed icon packs
- Bootstrap / Material UI / Tailwind mixed together
- brand colors used as decoration without state meaning
- duplicated information blocks
- internal codes as primary copy
- charts without an actionable decision
- components without operational purpose
```

General rule:

```text
If it does not help decide what to do now, it does not belong on the main screen.
```

## Revised Projects block

Do not show:

```text
0 activos
0 bloqueados
```

Use a professional empty state:

```text
Sin actividad actualmente.
Preparado para futuras automatizaciones.
```

Reason:

```text
Reserve future space without making the product feel empty or incomplete.
```

## Mockup applied to Control Center V2

```text
┌────────────────────────────────────┐
│ OpenClaw Control Center        ◐   │
│                                    │
│ 🟢 SISTEMA OPERATIVO               │
│ Puedes trabajar con normalidad.    │
│ Modelos avanzados no conectados.   │
│                                    │
│ Última actualización   16:42       │
│ Última lectura         bajo demanda│
│ Estado actual          Precaución  │
└────────────────────────────────────┘

┌───────────────┬───────────────┐
│ Trabajar      │ Feature       │
│ Sí            │ Sí            │
├───────────────┼───────────────┤
│ Bloqueos      │ Modo          │
│ No            │ Local         │
└───────────────┴───────────────┘

┌────────────────────────────────────┐
│ Señales                            │
│ ● Healthcheck              OK      │
│ ● Preflight                READY   │
│ ● OpenClaw                 OK      │
│ ● Uso recursos             Bajo    │
│ ● Modelo avanzado          No conectado │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ Proyectos                          │
│ Sin actividad actualmente.          │
│ Preparado para futuras automatizaciones. │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ Avisos y bloqueos                  │
│ No hay bloqueos activos.           │
│ Modelos avanzados no conectados.   │
└────────────────────────────────────┘

▸ Detalles técnicos
  schema_version, raw status, raw risk_level,
  raw recommended_mode, signals, confidence, staleness
```

## Future implementation restrictions

Allowed in future implementation PRs:

```text
- visual variables
- Tailwind-based layouts
- Lucide icons
- static component structure
- presentation-only changes
```

Prohibited without explicit approval:

```text
- backend
- runtime
- deploy
- control plane
- executor
- gateway
- Telegram/Gmail
- new signals
- new JSON sources
- business-rule recalculation in UI
```

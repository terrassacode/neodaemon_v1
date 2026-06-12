# OpenClaw Control Center V3

Centro de control modular para consultar el snapshot del Operational Control Plane aplicando OpenClaw Visual System V1.

## Fuente única

Lee únicamente:

```text
../data/operational_control_plane_v1.json
```

## Assets locales

V3 es local-offline y no usa CDN ni build:

```text
vendor/tailwind.css
vendor/lucide.min.js
```

Notas:

- `vendor/tailwind.css` contiene el subset local de utilidades Tailwind usado por esta pantalla.
- `vendor/lucide.min.js` contiene el subset local compatible con Lucide Icons usado por esta pantalla.
- No hay `package.json`, `node_modules`, Vite, npm ni pipeline de build.

## Principios V3

- Mobile-first.
- Dark-first.
- Minimalismo agresivo.
- Jerarquía visual clara.
- Información crítica visible en menos de 3 segundos.
- Todo lo técnico queda detrás de “Detalles técnicos”.
- Sin dashboards paralelos ni estilos externos.

## Alcance

- HTML/CSS/JS estáticos.
- No ejecuta Python.
- No llama APIs externas.
- No escribe archivos JSON ni modifica datos.
- No recalcula `status`, `risk_level` ni `recommended_mode`.
- No añade señales nuevas.
- No añade backend ni runtime.
- El bloque “Proyectos” es un estado vacío profesional: “Sin actividad actualmente”.
- No toca `dashboard-v2/index.html`, `dashboard-v2/tools/*` ni `dashboard-v2/data/*`.

## Uso esperado

1. Generar el snapshot con la acción controlada.
2. Publicar estos archivos con la acción controlada de deploy.
3. Abrir `dashboard-v2/operational-control-plane/index.html` desde el dashboard servido.

Si el snapshot no existe, la pantalla muestra un estado vacío humano claro.

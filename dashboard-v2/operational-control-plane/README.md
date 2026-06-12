# OpenClaw Control Center

Centro de control modular para consultar el snapshot del Operational Control Plane.

## Fuente única

Lee únicamente:

```text
../data/operational_control_plane_v1.json
```

## Principios V2

- Mobile-first.
- Dark mode nativo/local.
- Minimalismo agresivo.
- Jerarquía visual clara.
- Información crítica visible en menos de 3 segundos.
- Todo lo técnico queda detrás de “Detalles técnicos”.

## Alcance

- HTML/CSS/JS estáticos.
- No ejecuta Python.
- No llama APIs externas.
- No escribe archivos JSON ni modifica datos.
- No recalcula `status`, `risk_level` ni `recommended_mode`.
- No añade señales nuevas.
- No añade backend ni runtime.
- El bloque “Proyectos” es reserva visual futura y muestra valores fijos iniciales: `0 activos`, `0 bloqueados`.
- No toca `dashboard-v2/index.html`, `dashboard-v2/tools/*` ni `dashboard-v2/data/*`.

## Uso esperado

1. Generar el snapshot con la acción controlada.
2. Abrir `dashboard-v2/operational-control-plane/index.html` desde el dashboard servido.

Si el snapshot no existe, la pantalla muestra un mensaje humano claro.

# Operational Control Plane Dashboard

Dashboard modular aislado para consultar el snapshot del Operational Control Plane con una UX pensada para no programadores.

## Fuente única

Lee únicamente:

```text
../data/operational_control_plane_v1.json
```

## Alcance

- HTML/CSS/JS estáticos.
- No ejecuta Python.
- No llama APIs externas.
- No escribe archivos JSON ni modifica datos.
- No recalcula `status`, `risk_level` ni `recommended_mode`.
- Traduce valores técnicos en la pantalla principal y conserva los códigos en “Detalles técnicos”.
- Incluye modo oscuro local con `localStorage` del navegador.
- No toca `dashboard-v2/index.html`, `dashboard-v2/tools/*` ni `dashboard-v2/data/*`.

## Uso esperado

1. Generar el snapshot con la acción controlada.
2. Abrir `dashboard-v2/operational-control-plane/index.html` desde el dashboard servido.

Si el snapshot no existe, la pantalla muestra un mensaje humano claro.

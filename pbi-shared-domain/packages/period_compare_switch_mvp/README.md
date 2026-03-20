# Period Compare Switch MVP

First-wave semantic extraction from the legacy `SwitchPeriodMode` logic.

## Purpose

Provide a reusable selector that switches between:

- a short-horizon metric pair
- a rolling-horizon metric pair

and exposes selected current, selected reference, delta, and delta percent.

## Bindings

- `MOD_BIND_SHORT_CURRENT_MEASURE`
- `MOD_BIND_SHORT_REFERENCE_MEASURE`
- `MOD_BIND_LONG_CURRENT_MEASURE`
- `MOD_BIND_LONG_REFERENCE_MEASURE`

## Legacy source

- `SwitchPeriodMode`

## Notes

This first MVP extracts the semantic logic only. The visible table already exposes the period mode selector, so consumer authors can bind slicers and visuals directly on top of the installed table.

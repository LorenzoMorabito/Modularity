# Lag Correlation Explorer MVP

First-wave semantic extraction from the legacy lag and correlation analysis tables.

## Purpose

Provide a reusable lag explorer with:

- lagged driver metric
- response metric
- correlation by lag
- best lag diagnostics
- adstock diagnostic

## Bindings

- `MOD_BIND_DRIVER_MEASURE`
- `MOD_BIND_RESPONSE_MEASURE`
- `MOD_BIND_PERIOD_AXIS[Value]`

## Legacy source

- `SwitchLagSelection`
- `Lambda`
- `MaxLag`

## Notes

The visible table exposes the lag selector directly. Lambda and max-lag remain internal defaults in this first MVP.

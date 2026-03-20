# Metric Switch Selector MVP

First-wave semantic extraction from the duplicated selector tables in the legacy Product Analysis POC.

## Purpose

Provide a reusable metric switch table with:

- a collection-bound list of measures
- selected metric value output
- selected metric label output

## Bindings

- collection `measures`

## Legacy source

- `SwitchMeasureSelector (Sales)`
- `SwitchMeasureSelector (Promo)`
- `SwitchCompetitiveMeasureSelector`

## Notes

This package introduces the `metric-switch` rendering strategy so the selector rows are generated from the actual measure list chosen by the user.

# MebelFlow Asset Prep for SketchUp

SketchUp Ruby extension for converting existing furniture scenes into structured MebelFlow AI assets.

## Implemented

### Stage 0/1 — Visual review

- Root group/component validation.
- Recursive component tree scan using `persistent_id`.
- `HtmlDialog` review panel.
- Manual semantic role assignment persisted in `AttributeDictionary`.
- Bidirectional panel ↔ SketchUp selection.
- Viewport bounding-box highlighting without replacing materials.
- Focus, isolate overlay and “next undefined” workflow.

### Slice 2 — Asset Readiness Report

The report checks whether the selected furniture module is structurally ready for later export workflows. It does not upload files, call HTTP APIs, export GLB, calculate prices or interact with `mebelflow-ai`.

Commands:

- `Extensions → MebelFlow → Проверить готовность ассета`
- `Extensions → MebelFlow → Сохранить отчёт JSON`

The JSON command becomes available after a readiness check.

## Readiness statuses

- `ready` — no blocking errors or warnings.
- `ready_with_warnings` — all blocking rules pass, but optimization warnings exist.
- `not_ready` — one or more blocking rules failed.

## Readiness rules

Blocking:

1. At least one root object has role `MAIN_BODY` (`main_body` in the report semantics).
2. No exportable entity has role `UNDEFINED`.
3. No empty group/component exists.
4. Root and exportable entities have measurable positive bounding dimensions.
5. Model units are recognized and normalized to millimeters.

Non-blocking:

- Triangle count over 50,000 produces `high_polygon_count` warning.

Objects with roles `IGNORE` and `DELETE_FROM_PREPARED_COPY` are not considered exportable.

## Stable JSON schema

Both the report and nested asset manifest use schema version `1.0`.

```json
{
  "schema_version": "1.0",
  "report_type": "asset_readiness",
  "status": "ready_with_warnings",
  "ready": true,
  "checked_at": "2026-08-06T04:20:00Z",
  "summary": {
    "errors": 0,
    "warnings": 1,
    "infos": 0
  },
  "issues": [
    {
      "code": "high_polygon_count",
      "severity": "warning",
      "message": "Количество полигонов превышает рекомендуемый порог, но не блокирует готовность.",
      "entity_ids": [],
      "details": {
        "triangle_count": 62000,
        "threshold": 50000
      }
    }
  ],
  "asset_manifest": {
    "schema_version": "1.0",
    "asset_id": "tall-oven-600",
    "root": {
      "id": 101,
      "name": "Tall Oven 600",
      "dimensions_mm": {
        "width": 600.0,
        "depth": 580.0,
        "height": 2200.0
      }
    },
    "units": {
      "source": "millimeters",
      "normalized": "millimeters",
      "scale_to_mm": 1.0,
      "valid": true
    },
    "geometry": {
      "triangle_count": 62000
    },
    "items": []
  }
}
```

## Manual model-check scenario

1. Open a SketchUp model and select exactly one root group/component.
2. Run `Extensions → MebelFlow → Подготовить ассет`.
3. Assign `MAIN_BODY` to the selected root module.
4. Assign roles to every exportable nested group/component.
5. Mark non-exported objects as `IGNORE` or `DELETE_FROM_PREPARED_COPY`.
6. Run `Extensions → MebelFlow → Проверить готовность ассета`.
7. Click an issue or entity ID in the report to focus and highlight it in the 3D scene.
8. Correct the model and run the check again.
9. When satisfied, run `Extensions → MebelFlow → Сохранить отчёт JSON`.

## Tests

Readiness business rules run without SketchUp using simple Ruby doubles:

```bash
ruby test/readiness_rules_test.rb
```

Current Slice 2 test coverage includes all mandatory rules, non-blocking polygon warnings and schema version `1.0` serialization.

## Development installation

Copy:

- `mebelflow_asset_prep.rb`
- `mebelflow_asset_prep/`

into the SketchUp `Plugins` folder and restart SketchUp.

## Not implemented

- HTTP/API integration.
- Cloud upload.
- Authentication.
- GLB export.
- Price calculation.
- Changes to `mebelflow-ai`.
- Automatic polygon reduction.

## Runtime note

Ruby rules and syntax can be tested outside SketchUp. Viewport, menu and `HtmlDialog` behavior still require a manual test in SketchUp Desktop.

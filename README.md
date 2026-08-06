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

### Slice 3 — Prepared Copy

The Prepared Copy workflow creates a safe, deeply detached duplicate of the selected root module after a successful readiness check.

```text
Исходная SketchUp-модель
        ↓
Readiness Report: ready / ready_with_warnings
        ↓
Prepared Copy
  ├── удалены DELETE_FROM_PREPARED_COPY
  ├── сохранены IGNORE-объекты, но исключены из manifest
  ├── очищены и зафиксированы MebelFlow metadata
  └── создан manifest.json + report.json
        ↓
Ручной экспорт GLB из подготовленной копии
```

Command:

- `Extensions → MebelFlow → Создать Prepared Copy`

Prepared Copy behavior:

- the original selected module is not modified;
- copied component definitions are made unique recursively before destructive changes;
- `DELETE_FROM_PREPARED_COPY` objects are erased only from the copy;
- `IGNORE` objects remain in the copy but are omitted from `manifest.json`;
- metadata are normalized to schema version `1.0`;
- output is written to `<asset-id>-prepared/manifest.json` and `report.json`.

### Slice 4 — Asset Package & GLB Validation

Slice 4 works only with local files. It does not export GLB automatically and does not inspect GLB geometry. After manually exporting the prepared SketchUp object, select the resulting `.glb` file and run:

- `Extensions → MebelFlow → Собрать Asset Package`

The command becomes available after a Prepared Copy has been created.

The plugin performs simple local validation:

1. `manifest.json` exists;
2. `report.json` exists;
3. the selected file has the `.glb` extension;
4. the GLB exists on disk;
5. the GLB file size is greater than zero.

A valid package is stored in the existing prepared directory:

```text
<asset-id>-prepared/
├── manifest.json
├── report.json
├── <asset-id>.glb
└── package.json
```

The selected GLB is copied into the package under the canonical name `<asset-id>.glb`. `package.json` uses schema version `1.0` and records local file names, relative paths, existence, sizes and validation issues.

Example:

```json
{
  "schema_version": "1.0",
  "package_type": "mebelflow_asset",
  "status": "valid",
  "valid": true,
  "asset_id": "tall-oven-600",
  "files": {
    "manifest": {
      "name": "manifest.json",
      "relative_path": "manifest.json",
      "exists": true,
      "size_bytes": 2410
    },
    "report": {
      "name": "report.json",
      "relative_path": "report.json",
      "exists": true,
      "size_bytes": 3200
    },
    "glb": {
      "name": "tall-oven-600.glb",
      "relative_path": "tall-oven-600.glb",
      "exists": true,
      "size_bytes": 286440
    }
  },
  "issues": []
}
```

Possible blocking issue codes:

- `manifest_missing`;
- `report_missing`;
- `invalid_glb_extension`;
- `glb_missing`;
- `glb_empty`.

## Readiness statuses

- `ready` — no blocking errors or warnings.
- `ready_with_warnings` — all blocking rules pass, but optimization warnings exist.
- `not_ready` — one or more blocking rules failed.

## Readiness rules

Blocking:

1. At least one root object has role `MAIN_BODY`.
2. No exportable entity has role `UNDEFINED`.
3. No empty group/component exists.
4. Root and exportable entities have measurable positive bounding dimensions.
5. Model units are recognized and normalized to millimeters.

Non-blocking:

- Triangle count over 50,000 produces `high_polygon_count` warning.

Objects with roles `IGNORE` and `DELETE_FROM_PREPARED_COPY` are not considered exportable.

## Manual end-to-end scenario

1. Select one root group/component in SketchUp.
2. Run `Подготовить ассет` and assign semantic roles.
3. Run `Проверить готовность ассета`.
4. Correct blocking issues until status is `ready` or `ready_with_warnings`.
5. Run `Создать Prepared Copy` and choose a local output folder.
6. Verify the selected `[PREPARED]` copy.
7. Manually export only that copy as `.glb` from SketchUp.
8. Run `Собрать Asset Package`.
9. Select the manually exported GLB.
10. Verify that the prepared folder contains `manifest.json`, `report.json`, canonical GLB and `package.json`.
11. Confirm `package.json` status is `valid`.

## Tests

Business rules and local package validation run without SketchUp:

```bash
ruby test/readiness_rules_test.rb
ruby test/prepared_copy_plan_test.rb
ruby test/glb_validation_rules_test.rb
ruby test/asset_package_service_test.rb
```

## Development installation

Copy:

- `mebelflow_asset_prep.rb`
- `mebelflow_asset_prep/`

into the SketchUp `Plugins` folder and restart SketchUp.

## Explicitly not implemented

- HTTP/API integration;
- cloud upload;
- authentication;
- automatic GLB export;
- GLB geometry, material or binary-structure inspection;
- price calculation;
- changes to `mebelflow-ai`;
- automatic polygon reduction.

## Runtime note

Pure Ruby rules can be tested outside SketchUp. Menu commands, file dialogs, Prepared Copy behavior and final package assembly still require a manual test in SketchUp Desktop.

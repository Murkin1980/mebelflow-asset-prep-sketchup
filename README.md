# MebelFlow Asset Prep for SketchUp

SketchUp Ruby extension for converting existing furniture scenes into structured MebelFlow AI assets.

## Implemented in Stage 0/1

- Extension registration, menu and toolbar.
- Root group/component validation.
- Recursive component tree scan using `persistent_id`.
- `HtmlDialog` review panel.
- Manual role assignment persisted in `AttributeDictionary`.
- Bidirectional panel ↔ SketchUp selection.
- Viewport bounding-box highlighting without replacing materials.
- Focus, isolate overlay and “next undefined” workflow.

## Not implemented yet

- Automatic classifier.
- Working-copy cleanup.
- Standard hierarchy rebuild.
- Origin normalization.
- GLB and metadata export.
- Polygon optimization.

## Development installation

Copy:

- `mebelflow_asset_prep.rb`
- `mebelflow_asset_prep/`

into the SketchUp `Plugins` folder and restart SketchUp.

Then select exactly one group/component and run:

`Extensions → MebelFlow Asset Prep`

## Important

This code has been structurally reviewed but cannot be runtime-tested without SketchUp Desktop and its Ruby API.

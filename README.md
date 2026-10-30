# handlingeditor

Tune a car's handling in-game, feel the change straight away, and export the result as a `handling.meta` entry you can drop into your vehicle pack.

- 42 CHandlingData fields grouped into Body, Engine, Brakes & steering, Traction, Suspension and Damage, with search and a "changed only" filter
- Sliders and exact number inputs, with a marker showing the stock value and a one-click reset per field
- Undo and redo (Ctrl+Z / Ctrl+Y)
- Live telemetry while you drive: speed, RPM, gear, lateral and longitudinal g, top speed and an automatic 0-100 km/h timer
- Test drive mode: the editor folds down to the telemetry bar so you can drive, press the key again to keep editing
- Presets saved per player
- Export copies a ready `<Item type="CHandlingData">` block to your clipboard (and prints it to F8)
- Changes sync to everyone through the vehicle's state bag, and are checked and clamped on the server

Works with any framework. Needs [ox_lib](https://github.com/overextended/ox_lib).

## Install

```
ensure ox_lib
ensure handlingeditor

add_ace group.admin handling.edit allow
```

The built UI is included in `web/dist`, so there's nothing to build unless you change it.

## Usage

Sit in the driver's seat and run `/handling` (or set `Config.key`). Run it again, or press Esc in the editor, to switch between editing and test driving.

The 0-100 timer arms itself whenever you come to a stop. Pull away and it times you to 100 km/h, keeping your best for the session.

## Values are real handling.meta values

GTA stores a few fields differently in memory than in `handling.meta`: steering lock and the lateral traction curve are radians, top speed is divided by 3.6, the front bias fields are doubled, damping is divided by 10 and drag by 10,000. The editor converts both ways, so what you see and what you export are the numbers you'd write in the file.

`fDriveBiasFront` is the awkward one: a value of 1.0 in memory can mean pure FWD or a 50/50 split. The editor checks which wheels are actually powered to tell them apart.

## Things to know

- Not every field reacts the moment you change it. A few (gears, some suspension values) only fully settle after the car moves a bit or is respawned. Export and test with the real `handling.meta` before you ship a tune.
- Only `CHandlingData` is covered. Handling flags and sub-handling (bikes, boats, aircraft) aren't editable here.
- `handlingName` in the export is the model name. If your vehicle pack uses a different handling name, change it after pasting.

## Config

`config.lua`: command, keybind, ace, whether edits sync to other players, and how often telemetry updates. Field ranges and labels live in `shared/fields.lua`.

## Working on the UI

```bash
cd web
npm install
npm run dev     # opens in a browser with sample data
npm run build   # writes web/dist
```

## Support

Made by **IamZach**. Questions, bugs or ideas: [discord.gg/agn](https://discord.gg/agn)

## License

MIT

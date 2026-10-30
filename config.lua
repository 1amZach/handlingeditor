Config = {}

Config.command = 'handling'
Config.key = false -- e.g. 'F7', false to skip the keybind

-- Ace needed to use the editor. false lets everyone use it.
--   add_ace group.admin handling.edit allow
Config.ace = 'handling.edit'

-- Share edits with everyone else through the vehicle's state bag. When false, only you feel them.
Config.sync = true

-- How often the telemetry panel updates, in ms.
Config.telemetryRate = 66

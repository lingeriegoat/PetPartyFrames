--[[
PartyPetFrames is a World of Warcraft addon that manages party pet frames.

Copyright (C) 2019  Melik Noyan Baykal
Modified 2026 by lingeriegoat

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local _, ns = ...

local L = {}
ns.L = L

L.COMMANDS = function(cmd) return string.format("Commands: %s enable | %s disable | %s debug", cmd, cmd, cmd) end
L.LOADED   = "|cFF41a31aPartyPetFrames|r loaded. /ppf for commands."
L.ENABLED  = "|cFF41a31aPartyPetFrames|r is enabled. To disable: /ppf disable"
L.DISABLED = "|cFF41a31aPartyPetFrames|r is disabled. To enable: /ppf enable"
L.WILL_DEFER = "Unable to change the pet frame setting in combat. Will apply when combat ends."
L.NO_FRAMES  = "|cFF41a31aPartyPetFrames|r could not find the default party pet frames. Type /ppf debug and report the output."

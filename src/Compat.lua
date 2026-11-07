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

ns.MAX_PARTY = 4

ns.PET_CLASSES = { [3] = true, [9] = true }

function ns.Plain(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, value = pcall(fn, ...)
  if not ok then return nil end
  if type(_G.issecretvalue) == "function" then
    local okS, secret = pcall(_G.issecretvalue, value)
    if okS and secret then return nil end
  end
  return value
end

function ns.Raw(fn, ...)
  if type(fn) ~= "function" then return nil end
  local r = { pcall(fn, ...) }
  if not r[1] then return nil end
  return select(2, unpack(r))
end

function ns.GetMemberFrame(i)
  local pf = _G.PartyFrame
  if type(pf) == "table" then
    local m = pf["MemberFrame" .. i]
    if m then return m end
  end
  return _G["PartyMemberFrame" .. i]
end

function ns.GetPetFrame(i)
  local m = ns.GetMemberFrame(i)
  if type(m) == "table" then
    if m.PetFrame then return m.PetFrame end
    if m.petFrame then return m.petFrame end
  end
  return _G["PartyMemberFrame" .. i .. "PetFrame"]
end

function ns.GetPetHealthBar(petFrame, i)
  if type(petFrame) ~= "table" then return nil end
  local hb = petFrame.healthbar or petFrame.HealthBar or petFrame.healthBar
  if not hb and petFrame.HealthBarsContainer then hb = petFrame.HealthBarsContainer.HealthBar end
  if not hb then hb = _G["PartyMemberFrame" .. i .. "PetFrameHealthBar"] end
  return hb
end

function ns.InCombat()
  return InCombatLockdown and InCombatLockdown() and true or false
end

function ns.GetCVarValue(name)
  local getter = (C_CVar and C_CVar.GetCVar) or _G.GetCVar
  if type(getter) ~= "function" then return nil end
  local ok, v = pcall(getter, name)
  return ok and v or nil
end

function ns.SetCVarValue(name, value)
  local setter = (C_CVar and C_CVar.SetCVar) or _G.SetCVar
  if type(setter) ~= "function" then return false end
  return pcall(setter, name, value) and true or false
end

function ns.UsingRaidStyle()
  if EditModeManagerFrame and type(EditModeManagerFrame.UseRaidStylePartyFrames) == "function" then
    local ok, v = pcall(EditModeManagerFrame.UseRaidStylePartyFrames, EditModeManagerFrame)
    if ok then return v and true or false end
  end
  return ns.GetCVarValue("useCompactPartyFrames") == "1"
end

function ns.TryRegister(frame, event)
  return pcall(frame.RegisterEvent, frame, event)
end

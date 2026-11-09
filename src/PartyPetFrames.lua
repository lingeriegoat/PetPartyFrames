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

local ADDON_NAME, ns = ...
local L = ns.L

local ON, OFF = 1, 0
local MAX = ns.MAX_PARTY
local bars = {}
local pending = false

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end
local function IsEnabled() return PPF_IsEnabled == ON end

local function PartyCount()
  local n = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
  if not n or n < 0 then n = 0 end
  return math.min(n, MAX)
end

local function ShouldRun()
  return IsEnabled() and (IsInGroup() or IsInRaid()) and not ns.UsingRaidStyle()
end

local function ApplyCVar()
  local want = IsEnabled() and "1" or "0"
  if ns.GetCVarValue("showPartyPets") == want then return end
  if ns.InCombat() then
    Print(L.WILL_DEFER)
    ns.cvarDirty = true
    return
  end
  ns.SetCVarValue("showPartyPets", want)
  ns.cvarDirty = false
end

local function Refresh()
  pending = false
  if not ns.ready then return end
  local run = ShouldRun()
  local count = run and PartyCount() or 0
  for i = 1, MAX do
    if i <= count then
      bars[i]:Update(true)
    else
      bars[i]:Update(false)
      if not run or i > count then bars[i]:Clear() end
    end
  end
end

local function RequestRefresh()
  if pending then return end
  pending = true
  C_Timer.After(0, Refresh)
end

local function HookDefaults()
  local function hook(obj, name)
    if type(obj) == "table" and type(obj[name]) == "function" then
      pcall(hooksecurefunc, obj, name, RequestRefresh)
    elseif obj == nil and type(_G[name]) == "function" then
      pcall(hooksecurefunc, name, RequestRefresh)
    end
  end
  hook(nil, "PartyMemberFrame_UpdatePet")
  hook(nil, "PartyMemberFrame_UpdateMember")
  local pf = _G.PartyFrame
  if type(pf) == "table" then
    hook(pf, "UpdatePartyFrames")
    hook(pf, "UpdateMemberFrames")
  end
  for i = 1, MAX do
    local m = ns.GetMemberFrame(i)
    if type(m) == "table" then
      hook(m, "UpdatePet")
      hook(m, "UpdateMember")
      if m.PetFrame and type(m.PetFrame.HookScript) == "function" then
        pcall(m.PetFrame.HookScript, m.PetFrame, "OnShow", RequestRefresh)
      end
    end
  end
end

local function Debug()
  Print("|cFF41a31aPartyPetFrames debug|r")
  Print("enabled=" .. tostring(PPF_IsEnabled) .. " showPartyPets=" .. tostring(ns.GetCVarValue("showPartyPets"))
    .. " raidStyle=" .. tostring(ns.UsingRaidStyle()) .. " subgroup=" .. tostring(PartyCount()))
  Print("PartyFrame=" .. tostring(_G.PartyFrame ~= nil) .. " PartyMemberFrame1=" .. tostring(_G.PartyMemberFrame1 ~= nil)
    .. " UnitPowerPercent=" .. tostring(type(_G.UnitPowerPercent) == "function"))
  for i = 1, MAX do
    local m, p = ns.GetMemberFrame(i), ns.GetPetFrame(i)
    local hb = p and ns.GetPetHealthBar(p, i)
    Print(string.format("%d: member=%s pet=%s health=%s petUnit=%s shown=%s petSize=%sx%s healthSize=%sx%s", i,
      tostring(m and (m.GetName and m:GetName() or "anon")), tostring(p and (p.GetName and p:GetName() or "anon")),
      tostring(hb ~= nil), tostring(UnitExists("partypet" .. i)), tostring(p and p.IsShown and p:IsShown()),
      tostring(p and p.GetWidth and p:GetWidth()), tostring(p and p.GetHeight and p:GetHeight()),
      tostring(hb and hb.GetWidth and hb:GetWidth()), tostring(hb and hb.GetHeight and hb:GetHeight())))
  end
end

SLASH_PARTYPETFRAMES1 = "/ppf"
SlashCmdList["PARTYPETFRAMES"] = function(arg)
  arg = string.lower(arg or "")
  if arg == "enable" then
    PPF_IsEnabled = ON
    Print(L.ENABLED)
  elseif arg == "disable" then
    PPF_IsEnabled = OFF
    Print(L.DISABLED)
  elseif arg == "debug" then
    Debug()
    return
  else
    Print(L.COMMANDS("/ppf"))
    return
  end
  ApplyCVar()
  RequestRefresh()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    if PPF_IsEnabled == nil then PPF_IsEnabled = ON end
    for i = 1, MAX do bars[i] = ns.PetPowerBar.new(i) end

    for _, e in ipairs({
      "GROUP_ROSTER_UPDATE", "GROUP_JOINED", "GROUP_LEFT", "PLAYER_ENTERING_WORLD", "UPDATE_ACTIVE_BATTLEFIELD",
      "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_OTHER_PARTY_CHANGED", "UNIT_PORTRAIT_UPDATE",
      "LOCALPLAYER_PET_RENAMED", "CVAR_UPDATE", "PLAYER_REGEN_ENABLED", "EDIT_MODE_LAYOUTS_UPDATED",
    }) do ns.TryRegister(self, e) end
    for i = 1, MAX do
      for _, e in ipairs({ "UNIT_PET", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_HEALTH" }) do
        pcall(self.RegisterUnitEvent, self, e, "party" .. i, "partypet" .. i)
      end
    end

    ns.ready = true
    HookDefaults()
    ApplyCVar()
    Print(IsEnabled() and L.LOADED or L.DISABLED)
    RequestRefresh()
    C_Timer.After(2, function() HookDefaults() RequestRefresh() end)
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if ns.cvarDirty then ApplyCVar() end
    RequestRefresh()
  elseif event == "CVAR_UPDATE" then
    local name = ...
    if name == "useCompactPartyFrames" or name == "USE_RAID_STYLE_PARTY_FRAMES"
       or name == "showPartyPets" or name == "SHOW_PARTY_PETS" then
      RequestRefresh()
    end
  else
    RequestRefresh()
  end
end)

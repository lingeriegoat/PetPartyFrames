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

local Plain, Raw = ns.Plain, ns.Raw

local PetPowerBar = {}
PetPowerBar.__index = PetPowerBar
ns.PetPowerBar = PetPowerBar

function PetPowerBar.new(index)
  return setmetatable({
    index = index,
    playerUnit = "party" .. index,
    petUnit = "partypet" .. index,
    dirty = false,
  }, PetPowerBar)
end

function PetPowerBar:Build(petFrame)
  if self.bar and self.petFrame == petFrame then return true end
  if type(petFrame) ~= "table" or not petFrame.CreateTexture then return false end

  self.petFrame = petFrame
  self.health = ns.GetPetHealthBar(petFrame, self.index)

  local bar = self.bar
  if not bar then
    bar = CreateFrame("StatusBar", nil, petFrame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(bar)
    bar.bg:SetColorTexture(0, 0, 0, 0.45)
    self.bar = bar
  else
    bar:SetParent(petFrame)
  end

  bar:ClearAllPoints()
  local anchor = self.health or petFrame
  local h = (self.health and Plain(self.health.GetHeight, self.health)) or 8
  if not h or h < 2 then h = 8 end
  if self.health then
    bar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
  else
    bar:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    bar:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
  end
  bar:SetHeight(h)
  bar:SetFrameLevel((petFrame:GetFrameLevel() or 1) + 1)
  return true
end

local function PowerColor(unit)
  local ok, ptype, token = pcall(UnitPowerType, unit)
  if not ok then return 0.2, 0.4, 0.9 end
  local colors = _G.PowerBarColor
  local c = colors and ((token and colors[token]) or colors[ptype] or colors[0])
  if c then return c.r, c.g, c.b end
  return 0.2, 0.4, 0.9
end

local function Fill(bar, unit)
  local ptype = Raw(UnitPowerType, unit)
  if type(_G.UnitPowerPercent) == "function" and _G.CurveConstants and CurveConstants.ScaleTo100 then
    local ok, pct = pcall(UnitPowerPercent, unit, ptype, true, CurveConstants.ScaleTo100)
    if ok and pct ~= nil then
      if pcall(bar.SetMinMaxValues, bar, 0, 100) and pcall(bar.SetValue, bar, pct) then return true end
    end
  end
  local cur, max = Raw(UnitPower, unit), Raw(UnitPowerMax, unit)
  if cur ~= nil and max ~= nil then
    if pcall(bar.SetMinMaxValues, bar, 0, max) and pcall(bar.SetValue, bar, cur) then return true end
  end
  pcall(bar.SetMinMaxValues, bar, 0, 100)
  pcall(bar.SetValue, bar, 0)
  return false
end

function PetPowerBar:IsPetClass()
  local ok, _, _, classIndex = pcall(UnitClass, self.playerUnit)
  if ok and type(classIndex) == "number" then
    self.petClass = ns.PET_CLASSES[classIndex] or false
  end
  return self.petClass == true
end

function PetPowerBar:Present()
  local playerOk = UnitExists(self.playerUnit) and not UnitIsDeadOrGhost(self.playerUnit)
  local petOk = UnitExists(self.petUnit) and not UnitIsDead(self.petUnit)
  return playerOk and petOk and true or false
end

function PetPowerBar:SetFrameShown(shown)
  local pf = self.petFrame or ns.GetPetFrame(self.index)
  if type(pf) ~= "table" then return end
  if ns.InCombat() then
    self.dirty = true
    return
  end
  if shown then pcall(pf.Show, pf) else pcall(pf.Hide, pf) end
end

function PetPowerBar:Hide()
  if self.bar then self.bar:Hide() end
  self:SetFrameShown(false)
end

function PetPowerBar:Update(active)
  if not active then
    if self.bar then self.bar:Hide() end
    return
  end

  local pf = ns.GetPetFrame(self.index)
  if not pf then
    if self.bar then self.bar:Hide() end
    return
  end

  if not self:IsPetClass() or Plain(UnitOnTaxi, self.playerUnit) or not self:Present() then
    self:Hide()
    return
  end

  if not self:Build(pf) then return end
  self:SetFrameShown(true)

  local r, g, b = PowerColor(self.petUnit)
  self.bar:SetStatusBarColor(r, g, b, 1)
  Fill(self.bar, self.petUnit)
  self.bar:Show()
end

function PetPowerBar:Clear()
  self.petClass = nil
  self:Hide()
end

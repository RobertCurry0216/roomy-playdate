local roomy = {
  _VERSION = 'Roomy',
  _DESCRIPTION = 'Scene management for Playdate sdk, adapted from https://github.com/tesselode/roomy',
  _URL = '',
  _LICENSE = [[
    MIT License

    Copyright (c) 2022 Robert Curry

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]]
}

import "CoreLibs/object"
import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = playdate.graphics
----------------------------------------------------
-- Basic Room
----------------------------------------------------
class("Room").extends()

function Room:__tostring()
  return self.className
end

function Room:init()
  self._sprites = {}
end

function Room:enter(previous) end

function Room:leave(next)
  self:clear()
end

function Room:pause(previous)
  self:cacheSprites()
  self:clear()
end

function Room:resume(next)
  for _, spr in ipairs(self._sprites) do
    spr:add()
  end
end

function Room:clear()
  gfx.sprite.removeAll()
end

function Room:cacheSprites()
  self._sprites = gfx.sprite.getAllSprites()
end

----------------------------------------------------
-- Pause Room
----------------------------------------------------
-- will by default render the current view as a background
class("PauseRoom").extends(Room)

function PauseRoom:enter(...)
  PauseRoom.super.enter(self, ...)
  local img = gfx.getDisplayImage()
  self.bgSprite = gfx.sprite.new(img)
  self.bgSprite:setIgnoresDrawOffset(true)
  self.bgSprite:setCenter(0,0)
  self.bgSprite:moveTo(0,0)
  self.bgSprite:setZIndex(-1)

  self.bgSprite:add()
end

----------------------------------------------------
-- Room manager
----------------------------------------------------

local handler_functions = {
  "AButtonDown",
  "AButtonHeld",
  "AButtonUp",
  "BButtonDown",
  "BButtonHeld",
  "BButtonUp",
  "downButtonDown",
  "downButtonUp",
  "leftButtonDown",
  "leftButtonUp",
  "rightButtonDown",
  "rightButtonUp",
  "upButtonDown",
  "upButtonUp",
  "cranked",
  "crankDocked",
  "crankUndocked"
}

class("Manager").extends()

function Manager:printStack()
  local stack = ""
  for _, scene in ipairs(self._scenes) do
    stack = stack.."->"..tostring(scene)
  end
  return stack
end

function Manager:init()
  self._scenes = {{}}
end

function Manager:hook(options)
  options = options or {}
  local to_include = options.include or handler_functions
  local to_exclude = options.exclude or {}
  for _, v in ipairs(to_exclude) do
    local i = table.indexOfElement(to_include, v)
    if i then
      table.remove(to_include, i)
    end
  end

  local handler = {}
  for _, v in ipairs(to_include) do
    handler[v] = function(...) self:emit(v, ...) end
  end
  pd.inputHandlers.push(handler)
end

function Manager:emit(event, ...)
  local scene = self._scenes[#self._scenes]
  if scene and scene[event] then scene[event](scene, ...) end
end

function Manager:enter(next, ...)
  local previous = self._scenes[#self._scenes]
  self:emit('leave', next, ...)
  self._scenes[#self._scenes] = next
  self:emit('enter', previous, ...)
end

function Manager:resetAndEnter(next, ...)
  while #self._scenes > 1 do
    self:pop(...)
  end
  self:enter(next, ...)
end

function Manager:push(next, ...)
  local previous = self._scenes[#self._scenes]
  self:emit('pause', next, ...)
  self._scenes[#self._scenes + 1] = next
  self:emit('enter', previous, ...)
end

function Manager:pop(...)
  local previous = self._scenes[#self._scenes]
  -- always keep at least one scene active
  if previous == nil or #self._scenes < 2 then return end

  local next = self._scenes[#self._scenes - 1]
  self:emit('leave', next, ...)
  self._scenes[#self._scenes] = nil
  self:emit('resume', previous, ...)
end

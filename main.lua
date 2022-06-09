import "CoreLibs/object"
import "CoreLibs/graphics"
import "roomy"

class("RoomA").extends(Room)

function RoomA:enter()
  local s = playdate.graphics.sprite.new()
  s:setSize(400, 120)
  s:setCenter(0,0)
  s:moveTo(0,0)

  function s:draw()
    playdate.graphics.drawText("room A", 10,10)
  end

  s:add()
end

function RoomA:BButtonDown()
  manager:push(RoomB())
end

class("RoomB").extends(Room)

function RoomB:enter()
  local s = playdate.graphics.sprite.new()
  s:setSize(400, 120)
  s:setCenter(0,0)
  s:moveTo(0,0)

  function s:draw()
    playdate.graphics.drawText("room B", 10,10)
  end

  s:add()
end

function RoomB:AButtonDown()
  manager:pop()
end

manager = Manager()
manager:hook()
manager:enter(RoomA())

function playdate.update()
  playdate.graphics.sprite.update()
  manager:emit('update')
end
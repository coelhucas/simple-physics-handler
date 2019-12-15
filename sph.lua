local SPH = {}
local Actor = {}
local mtActor = { __index = Actor }
local Solid = {}
local mtSolid = { __index = Solid }
actors = {}
solids = {}

-- Utils math functions

function math.round(n, deci)
  deci = 10 ^ (deci or 0)
  return math.floor(n * deci + .5) / deci
end

function math.sign(n)
  return n > 0 and 1 or n < 0 and -1 or 0
end

local function hasValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- SPH functions

function SPH.newActor(x, y, w, h, tags)
  actorObj = Actor.new(x, y, w, h, tags)
    -- Register our new actor
  actors[table.getn(actors) + 1] = actorObj
  return actorObj
end

function SPH.setLinearVelocity(vector, onCollide)
  return actor:setLinearVelocity(vector, onCollide, solids)
end

function SPH.newSolid(x, y, w, h, tags)
  solidObj = Solid.new(x, y, w, h, tags)
  -- Register new solid
  solids[table.getn(solids) + 1] = solidObj

  return solidObj
end

function SPH.draw(alpha)
  Actor:draw(alpha)
  Solid:draw(alpha)
end

-- Actor Object

function Actor.new(x, y, width, height, tags)
  local actor = {}

  actor.x = x
  actor.y = y
  actor.w = width
  actor.h = height
  actor.xRemainder = 0
  actor.yRemainder = 0
  actor.tags = {'actor'}

  if (tags ~= nil) then
    for k, tag in ipairs(tags) do
      actor.tags[table.getn(actor.tags) + 1] = tag
    end
  end

  setmetatable(actor, mtActor)

  return actor
end

function Actor:collideAt(solids, vector)
  hasCollision = false

  if (solids == nil) then
    return false
  end

  for key, solid in ipairs(solids) do
    x = solid.x
    y = solid.y
    w = solid.w
    h = solid.h

    if (solid ~= self) then
      hasCollision = (self.x + vector.x < x + w and
              self.x + self.w + vector.x > x and
              self.y + vector.y < y + h and
              self.y + self.h + vector.y > y)
    end

    if (not solid.collidable) then
      hasCollision = false
    end

    if (hasCollision) then
      return true, solid
    end
  end
  return false
end

function Actor:triggerAt(actors, vector)
  hasCollision = false

  if (actors == nil) then
    return false
  end

  for key, actor in ipairs(actors) do
    x = actor.x
    y = actor.y
    w = actor.w
    h = actor.h

    if (actor ~= self) then
      hasCollision = (self.x + vector.x < x + w and
              self.x + self.w + vector.x > x and
              self.y + vector.y < y + h and
              self.y + self.h + vector.y > y)
    end

    if (hasCollision) then
      return true, actor
    end
  end
  return false
end

function Actor:moveX (amount, onCollide)
  self.xRemainder = self.xRemainder + amount
  move = math.round(self.xRemainder)

  if (move ~= 0) then
    self.xRemainder  = self.xRemainder - move
    sign = math.sign(move)

    while (move ~= 0) do
      collisionVector = { x = sign, y = 0 }
      triggerAt, trigger = self:triggerAt(actors, collisionVector)
      if (triggerAt and onCollide ~= self.squish) then
        onCollide(trigger)
      end

      collideAt, collider = self:collideAt(solids, collisionVector)
      if (not collideAt) then
        self.x = self.x + sign
        move = move - sign
      else
        if (onCollide ~= nil) then
          onCollide(self, collider)
        end
        break
      end
    end
  end
end

function Actor:moveY (amount, onCollide)
  self.yRemainder = self.yRemainder + amount
  move = math.round(self.yRemainder)

  if (move ~= 0) then
    self.yRemainder = self.yRemainder - move
    sign = math.sign(move)

    while (move ~= 0) do
      collisionVector = { x = 0, y = sign }
      triggerAt, trigger = self:triggerAt(actors, collisionVector)
      if (triggerAt and onCollide ~= self.squish) then
        onCollide(trigger)
      end

      collideAt, collider = self:collideAt(solids, collisionVector)
      if (not collideAt) then
        self.y = self.y + sign
        move = move - sign
      else
        if (onCollide ~= nil) then
          onCollide(collider)
        end
        break
      end
    end
  end
end

function Actor:setLinearVelocity (vector, onCollide)
  if (vector.x ~= nil) then
    self:moveX(vector.x, onCollide, sollids)
  end

  if (vector.y ~= nil) then
    self:moveY(vector.y, onCollide, sollids)
  end
end

function Actor:squish()
  -- The squish is a separated function equals to destroy in case you want to override it
  for key, actor in ipairs(actors) do
    --print(self)
    if (actor == self) then
      print('iole irro')
      table.remove(actors, key)
      break
    end
  end
end

function Actor:destroy()
  for key, actor in ipairs(actors) do
    if (actor.tags == self.tags) then
      table.remove(actors, key)
    end
  end
end

function Actor:draw(alpha)
  for k, actor in ipairs(actors) do
    love.graphics.setColor(0.2, 1, 0.2, alpha ~= nil and alpha or 1)
    love.graphics.rectangle('line', actor.x, actor.y, actor.w, actor.h)
  end
end

function Actor:isRiding(solid)
  return self:collideAt({ solid }, { x = 0, y = 1 })
end

-- Solids
function Solid.new(x, y, width, height, tags)
  local solid = {}

  solid.x = x
  solid.y = y
  solid.w = width
  solid.h = height
  solid.xRemainder = 0
  solid.yRemainder = 0
  solid.tags = {'solid'}
  solid.collidable = true

  if (tags ~= nil) then
    for k, tag in ipairs(tags) do
      solid.tags[table.getn(tags) + 1] = tag
    end
  end

  setmetatable(solid, mtSolid)

  return solid
end

function Solid:isOverlapping(actor)
  return (self.x < actor.x + actor.w and
          self.x + self.w > actor.x and
          self.y < actor.y + actor.h and
          self.y + self.h > actor.y)
end

function Solid:move(x, y)
  self.xRemainder = self.xRemainder + x
  self.yRemainder = self.yRemainder + y
  moveX = math.round(self.xRemainder)
  moveY = math.round(self.yRemainder)

  if (moveX ~= 0 or moveY ~= 0) then
    riding = {}

    for key, actor in ipairs(actors) do
      if (actor:isRiding(self)) then
        table.insert(riding, actor)
      end
    end

    self.collidable = false

    if (moveX ~= 0) then
      self.xRemainder = self.xRemainder - moveX
      self.x = self.x + moveX

      if (moveX > 0) then
        for key, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveX(moveX, actor.squish, actor)
          elseif (hasValue(riding, actor)) then
            actor:moveX(moveX)
          end
        end
      else
        for key, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveX(moveX)
          elseif (hasValue(riding, actor)) then
            actor:moveX(moveX)
          end
        end
      end
    end
  end

  if (moveY ~= 0 or moveY ~= 0) then
    riding = {}

    for key, actor in ipairs(actors) do
      if (actor:isRiding(self)) then
        table.insert(riding, actor)
      end
    end

    self.collidable = false

    if (moveY ~= 0) then
      self.yRemainder = self.xRemainder - moveX
      self.y = self.y + moveY

      if (moveY > 0) then
        for key, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveY(moveY, actor.squish)
          elseif (hasValue(riding, actor)) then
            actor:moveY(moveY)
          end
        end
      else
        for key, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveY(moveY)
          elseif (hasValue(riding, actor)) then
            actor:moveY(moveY)
          end
        end
      end
    end
  end

  self.collidable = true
end

function Solid:draw(alpha)
  for k, currentSolid in ipairs(solids) do
    love.graphics.setColor(1, 0.2, 0.2, alpha ~= nil and alpha or 1)
    love.graphics.rectangle('line', currentSolid.x, currentSolid.y, currentSolid.w, currentSolid.h)
  end
end

return SPH

# SPH.lua

Lua physics handling library for axis-aligned rectangles. It was made for simple and fast prototyping and even simple game creations. It was made based on [this towarfall developer's post](!https://mattmakesgames.tumblr.com/post/127890619821/towerfall-physics). This library was made focusing in LÖVE framework, so the examples will be based on it.

It automagically handle collisions and callbacks for objects overlapping accordingly to your needings.

## Example

```lua
local sph = require 'sph'

function love.load()
  player = sph.newActor(64, 32, 32, 32, { 'player' })
  collectible = sph.newActor(256, 32, 8, 8, { 'collectible'})
  wall = sph.newSolid(0, 0, 16, 640)
  collected = false
end

function handleCollision(collider)
  if (collider.tags[2] == 'collectible') then -- I'm doing this hardcoded but on a real life project you'll not do that
    print('collect the item')
    collider:destroy()
    collected = true
  end
end

function love.update()
  if (not collected) then
    player:setLinearVelocity({ x = 3 }, handleCollision)
  end
end

function love.draw()
  sph.draw(0.5) -- here we draw every collision shape with an alpha of 50%
end
```

Running the snippet the result will be:
[](!http://www.giphy.com/gifs/gicmo9lfTmpNQZ1aPU)
And in your console you should see `collect the item` printed.
As the reference post I linked above, it also handles Actor squish by default as destroying it. It's a separated function from `destroy` so you can override it as you want.

## API

```lua
actor = sph.newActor(x, y, width, height, tags = { 'projectile', 'hitbox' }) -- default tag[1] = 'actor'
solid = sph.newSolid(x, y, width, height, tags = { 'elevator' }) -- default tag[1] = 'solid'

actor:setLinearVelocity({ x = 1, y = 2 }, onCollide = callback function called when collision is triggered)
-- moves the actor
-- onCollide will be called both for solids and actors, returning the trigger (for actors) or collider object

actor:destroy() -- destroys the actor
solid:move(x, y) -- moves the solid

sph.draw(alpha) -- draws every object on screen with the desired alpha (0 - 1)
```

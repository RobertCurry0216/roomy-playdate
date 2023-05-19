# Roomy-Playdate

[![Toybox Compatible](https://img.shields.io/badge/toybox.py-compatible-brightgreen)](https://toyboxpy.io)

**Roomy-playdate** is a scene management library for the Playdate console by Panic. It helps organize game code by the different "screens" in the game, such as the title screen, gameplay screen, and pause screen. Roomy was originally written for LÖVE by tesselode [Github link](https://github.com/tesselode/roomy)

# Install

### Toybox

You can add it to your Playdate project by installing toybox.py, going to your project folder in a Terminal window and typing:

```lua
toybox add roomy
toybox update
```

Then, if your code is in the source folder, just import the following:

```lua
import '../toyboxes/toyboxes.lua'
```

### Manual install

To install roomy, simply copy the roomy-playdate.lua file into your game directory and import it into your game.

```lua
import "roomy-playdate"
```

## Usage

### Defining scenes

A scene is defined by extending the `Room` or `PauseRoom` classes

```lua
class("Gameplay").extends(Room)

function Gameplay:enter(previous, ...)
	-- set up the level
end

function Gameplay:update(dt)
	-- update entities
end

function Gameplay:leave(next, ...)
	-- destroy entities and cleanup resources
end

function Gameplay:draw()
	-- draw the level
end
```

A scene table can contain anything, but it will likely have some combination of functions corresponding to input callbacks and Roomy events.

The `PauseRoom` is a convience class that will by default take a screen shot of the previous room and set it as the background sprite.

### Creating a scene manager

```lua
local manager = Manager()
```

Creates a new scene manager. You can create as many scene managers as you want, but you'll most likely want one global manager for the main scenes of your game.

### Switching scenes

```lua
manager:enter(scene, ...)
```

Changes the currently active scene.

### Pushing/popping scenes

```lua
manager:push(scene, ...)
manager:pop()
```

Managers use a stack to hold scenes. You can push a scene onto the top of the stack, making it the currently active scene, and then pop it, resuming the previous state where it left off. This is useful for implementing pause screens, for example:

```lua
class("Pause").extends(PauseRoom)

function Pause:BButtonPressed()
	manager:pop()
end

class("Game").extends(Room)
function Game:BButtonPressed()
	manager:push(Pause())
end
```

There will always be at least one scene and calling `pop` when there is only one scene will have no effect.

### Emitting events

```lua
manager:emit(event, ...)
```

Calls `scene:[event]` on the active scene if that function exists. Additional arguments are passed to `scene.event`.

### Hooking into Playdate input callbacks

```lua
manager:hook(options)
```

Pushes an input handler that will emit events for each callback. `options` is an optional table with the following keys:

- `include` - a list of callbacks to hook into. If this is defined, _only_ these callbacks will be overridden.
- `exclude` - a list of callbacks _not_ to hook into. If this is defined, all of the callbacks except for these ones will be overridden.

As an example, the following code will cause the scene manager to hook into every callback except for `AButtonDown` and `AButtonHeld`.

```lua
manager:hook {
	exclude = {'AButtonDown', 'AButtonHeld'},
}
```

### Scene callbacks

Scenes have a few special callbacks that are called when a scene is switched, pushed, or popped.

```lua
function scene:enter(previous, ...) end
```

Called when a manager switches _to_ this scene or if this scene is pushed on top of another scene.

- `previous` - the previously active scene, or `{}` if there was no previously active scene
- `...` - additional arguments passed to `manager:enter` or `manager:push`

```lua
function scene:leave(next, ...) end
```

Called when a manager switches _away from_ this scene or if this scene is popped from the stack.

- `next` - the scene that will be active next
- `...` - additional arguments passed to `manager:enter` or `manager:pop`

```lua
function scene:pause(next, ...) end
```

Called when a scene is pushed on top of this scene.

- `next` - the scene that was pushed on top of this scene
- `...` - additional arguments passed to `manager:push`
- the `Room` class will cache and remove all current sprites

```lua
function scene:resume(previous, ...) end
```

Called when a scene is popped and this scene becomes active again.

- `previous` - the scene that was popped
- `...` - additional arguments passed to `manager:pop`
- the `Room` class will add all sprites that were cached when the scene was paused

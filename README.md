Ludos is a networking engine for synchronized real-time multiplayer games. It includes a Python game server and a
Javascript client library.

A synchronized real-time game has the following characteristics:

- The game is divided into "timesteps", typically 25ms - 100ms in length
- Each player can perform an arbitrary number of actions in a single timestep
- The full game state is mirrored and simulated on all players' computers
- The game state advances for a player only when the actions, or lack thereof, of all other players are available
- To compensate for latency, player actions are scheduled several timesteps after they are input, typically 100ms - 200ms in the future.

This networking model is commonly used in real-time strategy games, and is also suitable for some arcade and action games. It is not suitable
for games such as first-person shooters, where up to 200ms of input latency and occasional game freezes due to network latency are not acceptable.

The Ludos server is designed to require no modification specific to the game being implemented. The client library provides a simple API for
connecting to the game server and sending a player's actions, and dispatches events when other players' actions are available and the game
state may be advanced.

Ludos also provides a number of additional optional components:

- A flexible and modular user interface that allows players to create, find, and join games, shows
the status of players within a game, provides an interface for chat and game logs, and much more.
- A jQuery plugin that automatically synchronizes keyboard and mouse events on an element, calling an
event handler for events fired by *any* player when appropriate.
- A synchronized random number generator, ensuring that the game state is mirrored deterministically
among players even when random numbers are used.
- A replay system that automatically saves player actions during the game and can play them back later at
original or increased speed.

### Dependencies

* Core client: None!
* Optional UI: [jQuery](http://www.jquery.com), [Agility.js](http://www.agilityjs.com)
* Server: [Tornado](http://www.tornadoweb.org/en/stable/)

### Browser support

Requires full [WebSocket support](http://caniuse.com/#feat=websockets):

* Firefox 11+
* Chrome 14+
* Safari 6.0
* IE 10.0

### Installation

To be written...


### Documentation

To be written...


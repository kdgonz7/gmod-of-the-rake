
<div align="center">
	<img src="logo.png">
</div>
<hr>
A Garry's Mod gamemode where you have to kill the rake. The rake is very fast, and has a lot of health. So it's not smart to go alone, however, if you can kill it, you are rewarded as being
the top soldier in your country.

![rake](src/Rake%20Vid%2001.gif)

The rake is fast and stronger than you might think, to fight it you need to be predicted, and articulated.

![rak2](src/Rake%20Vid%2002.gif)

## How to play

For each version, it is recommended to stay up to date on the [Requirement Collection](https://steamcommunity.com/sharedfiles/filedetails/?id=3292769727)

### v0.0.1 (current)

To play the actual game, you need to have a NavMesh in your map. 
This means that the map owner, or you, have to build one.

> ⚠️ AI Nodes are also required if you have `rake_UseForTracking` set to `ainodes`

The DrGBase RAKE requires a navmesh in order to be able to walk 
around and find you. Or your friends. However, a navmesh is *NOT* 
required to spawn loot or the rake in the map.

Both are recommended, as AI Nodes have less chances of getting the rake stuck when being spawned.
But to configure this, use `rake_UseForTracking`.

<hr>

To start the game, type in `rake_StartGame` into the console or use the `E` key. (or whichever key you have binded to `USE`)

> 📝 To end the match early, please use `rake_EndMatch`. do note in 
> this version players are not allowed to join mid-game.

## Settings

### `rake_UseForTracking`

Allows you to change what is used for location processing.

Available values: `ainodes`, `navmesh`

### `rake_ArmorEnabled`

Allows you to change if players should start with armor 100% on spawn.

Available values: `1`, `0`

### `rake_Difficulty`

Allows you to change the difficulty of the game.

Available values: `1, 2< (can be higher, but just multiplies values by this number)`

### `rake_FogEnabled`

Allows you to change if the fog should be enabled.

Available values: `1`, `0`

## Variables

### `rake_GameState`

The current state of the game.

> 📝 while it may seem like a safety hazard, it will not allow 
> for any changes in the actual game when modified, it will 
> be overridden. this is primarily for client side usage.

### `rake_EnemySpawnFrequency`

> :dna: This variable is deprecated, as the functionality it provides sustinance to
> is no longer in use. This will be removed in a future version

The spawn frequency of the enemies.

## Credits

- [The Rake Nextbot by Painkiller76](https://steamcommunity.com/sharedfiles/filedetails/?id=2474152916)
- [Modern Warfare Base by Viper](https://steamcommunity.com/sharedfiles/filedetails/?id=2459720887)
- [FPS Saving Fog by 'shes got smiledog ancestory'](https://steamcommunity.com/sharedfiles/filedetails/?id=2925774481)
- [Alien: Isolation Motion Tracker (VManip) by MrSlonik](https://steamcommunity.com/sharedfiles/filedetails/?id=3100506899)
- [Extended Flashlight by SelMash & Shaky](https://steamcommunity.com/sharedfiles/filedetails/?id=2947598424)

## Required Addons

Uses a modified version of ["The Rake Nextbot"](https://steamcommunity.com/sharedfiles/filedetails/?id=2474152916), you will not have to install this separately, as it is packaged within the gamemode.

* Modern Warfare Base (and the other SWEPs, it spawns in range of however many you have)
* FPS Saving Fog

* Movement: Reworked (not required, but fun for realistic movement)
* Alien: Isolation Motion Tracker (VManip) (not required, but you might need it)
* Extended Flashlight

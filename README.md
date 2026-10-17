# Kitbash Toy Clash

This is a [Dev Pods](https://devpods.gg) game.

## Resources

- [Trello](https://trello.com/b/ZWjghYds/kitbash-toy-clash)
- [Kickoff deck](https://docs.google.com/presentation/d/1dHYSkgpurtwsd0BJkA-YCkfRnZW7nSyQeHMQLWfJHZ4/edit?usp=sharing)
- [Original design doc](https://docs.google.com/document/d/1izhstFtaS63s51HdFXqTnpzcqQeGZG2qYV6SR0O9RnA/edit?usp=sharing)
- [Playable build](https://markguinn.github.io/kitbash-toy-clash/) (updated on push to main)

## Contribution Guidelines

- please don't commit artifacts generated with AI
- no need for a pull request - just push to main
- if you're working in an area that might conflict with other's work it's nice to post in the channel first
- commit and push often, even if you're not done. this reduces merge conflicts and helps others know work is happening
- do your best to follow the [GDScript suggested style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- be kind to each other

## Palette

![Color Palette](palette.png)

## Folder structure

In general, I prefer snake_case naming and "vertical" organization (organize by 
feature group rather than file type - e.g. all the scripts, art, scenes, etc for 
a given enemy in one folder instead of spread across scripts, scenese, etc folders).

- `_ignored_assets` - this is gitignored, so you can put big files etc there while you're working on them and they won't get committed
- `_references` - reference images, design resources, etc
- `_source_assets` - unless they're hundreds of mb's or something, please commit your `psd`, `asprite`, `bbmodel`, `blend` etc files here (it's also ok to colocate them with the assets if that makes sense)
- `common` - shared behaviors such as HitBox, reusable VFX, etc
- `enemies` - enemy and enemy spawners (in a subfolders per enemy type)
- `globals` - scripts and scenes that are set up as global in the project (or used statically)
- `levels` - level scenes, probably one subfolder per biome, and further subfolders as needed to keep things clean
- `music` - music files can go here since they'll likely be shared across levels and parts of the game
- `player` - everything to do with player scenes, scripts, art, etc
- `props` - collectible items, switches, teleporters, etc.
- `ui` - we'll put all the ui screens and subscenes (title screen, pause menu, etc) here, with subfolders as needed

Within a folder for a given level, enemy, etc. we can follow a structure like:

- `player/`
  - `art/` - models, textures, etc
  - `sfx/` - sound files
  - `states/` - if needed, scripts for state machine nodes
  - `player.tscn` - main scene file
  - `player.gd` - main script file

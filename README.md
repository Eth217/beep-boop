# Reimagined Spoon

Godot game project.

## Team setup

1. Install [Git for Windows](https://git-scm.com/download/win).
2. Download the **Standard** Windows edition of [Godot 4.7.2](https://godotengine.org/download/windows/). Use the Standard edition unless the project is intentionally changed to C#/.NET.
3. Clone the repository:

   ```powershell
   git clone https://github.com/yovahn/reimagined-spoon.git
   cd reimagined-spoon
   ```

4. In Godot's Project Manager, select **Import**, choose this repository folder, and open `project.godot`.

5. Press **F6** or the play button to run the starter world. Move the placeholder character with **WASD** or the arrow keys.

## Development notes

- Engine: Godot 4.7.2 (Standard)
- Script language: GDScript
- Keep the Godot-generated `.godot/` folder out of version control. It is recreated automatically.
- Before making changes, run `git pull`.
- After testing your work, use `git status`, `git add`, `git commit`, and `git push` to share it.

## Starter world

The project contains a deliberately small playable scene: one screen-sized world, a circular placeholder character, and solid obstacles. It is the foundation for later maps, characters, and interactions.

Important project files:

- `project.godot`: Godot project settings and startup scene.
- `scenes/world.tscn`: The starter world scene.
- `scripts/player.gd`: Player movement.
- `scripts/world.gd`: World visuals and obstacle collision.

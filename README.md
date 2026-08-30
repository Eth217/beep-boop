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

## LAN co-op test

1. Run the project in one Godot window and select **Host LAN game**.
2. Run a second copy of the project. Enter the host computer's LAN IPv4 address (use `ipconfig` on Windows to find it) and select **Join game**. For two copies on the same computer, use `127.0.0.1`.
3. Each player starts with 100 health and uses **WASD** or the arrow keys. Press **Space** while moving to make a very short dash that accelerates, then decelerates; it has a three-second cooldown. Aim with the mouse and hold the left mouse button to fire. Hold the right mouse button for three seconds, then release it to launch a slower, larger fireball for 50 damage; the charge bar above the player turns bright when it is ready, and regular fire is disabled while charging. Standard hits remove 10 health, shown above each player. When one player reaches zero health, the round stops, both players see their win/loss result, and either can select **Start over**. Bullets disappear when they hit a player, wall, or obstacle. The host simulates movement, health, and bullets, then sends their state to all clients.

The prototype uses UDP port `7000`. If a second computer cannot join on the same network, allow Godot through Windows Firewall for private networks.

## Tests

Run the headless collision regression test with:

```powershell
godot --headless --path . --script tests/player_collision_test.gd
```

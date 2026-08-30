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

## Development notes

- Engine: Godot 4.7.2 (Standard)
- Script language: GDScript
- Keep the Godot-generated `.godot/` folder out of version control. It is recreated automatically.
- Before making changes, run `git pull`.
- After testing your work, use `git status`, `git add`, `git commit`, and `git push` to share it.

## First project setup

This repository currently has no Godot project files. Create the project in the repository root, then commit the generated `project.godot`, scenes, scripts, and assets. Do not commit `.godot/`.

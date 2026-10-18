# Local Frontier — serverless Godot reconstruction

The binding reconstruction requirements are documented in [REBUILD_RULES.md](REBUILD_RULES.md). The previous layout was only a prototype and is not considered UI-complete.

This prototype runs without a backend. Player state is stored in Godot's local `user://local_save.json` file.

Implemented loop:

- Main status screen
- Auto battle and stage rewards
- Unit enhancement
- Local shop/battle view toggle
- Save reset

The source reconstruction notes and decompiled reference material remain outside this project in `../ef_decompiled`.

# Cassiopeia: Resonance of the Rift
# Кассиопея: Резонанс Разрыва

## Hard Sci-Fi Immersive Sim / Action-RPG

### Project Structure

```
cassiopeia/
├── project.godot               # Main project config (1.4g gravity, input mappings)
├── scenes/
│   ├── player/player.tscn      # Player CharacterBody3D + camera + raycasts
│   ├── levels/
│   │   ├── prologue_zone.tscn  # Чрево (lower tier) — starting area
│   │   ├── telo_zone.tscn      # Тело (middle tier) — markets, residential
│   │   ├── nebo_zone.tscn      # Небо (upper tier) — elite, research
│   │   └── final_battle.tscn   # HΨ=0 — equation modification
│   ├── ui/
│   │   ├── hud.tscn            # HUD overlay (ATF/HP/O2/Echo/Runes/Dialogue)
│   │   └── distribution_menu.tscn # Archetype selection
│   ├── enemies/
│   ├── npc/
│   ├── items/
│   └── effects/
├── scripts/
│   ├── singletons/
│   │   ├── atf_balance.gd      # Аксиома Вериса (V=-k·ΔH) — metabolic economy
│   │   ├── gravity_manager.gd  # 1.4g gravity + fall damage + zones
│   │   ├── resonance_engine.gd # Resonance effects, quantum tunnels, density change
│   │   ├── runes_registry.gd   # 10 fundamental runes + crafting combos
│   │   ├── poler_system.gd     # ℘–O–L–ε–R[n] mechanics
│   │   ├── game_state.gd       # Global state, tiers, factions, endings
│   │   ├── economy_manager.gd  # Items, corals, vendors, consumables
│   │   ├── quest_manager.gd    # Quest chains (prologue → midgame → endgame)
│   │   ├── dialogue_system.gd  # Branching dialogue affecting endings
│   │   └── sound_manager.gd    # Audio system
│   ├── player/
│   │   └── player_controller.gd # Movement, combat, rune activation, perception
│   ├── enemies/
│   │   └── enemy_base.gd       # Adaptive AI (ε plasticity, faction-based)
│   ├── npc/
│   │   └ npc_base.gd           # NPC wander, interact, vendor, quest giver
│   ├── levels/
│   │   ├── prologue_zone.gd    # Чрево environment + setup
│   │   ├── telo_zone.gd        # Тело environment + NPC setup
│   │   ├── nebo_zone.gd        # Небо + endgame content
│   │   └── final_battle.gd     # HΨ=0 equation modification
│   ├── ui/
│   │   ├── hud.gd              # HUD signal connections + updates
│   │   ├── distribution_menu.gd # Archetype selection/customization
│   │   └── rune_crafting_ui.gd # Rune crafting interface
│   ├── systems/
│   │   ├── save_load_system.gd # Save/load game state
│   │   └ game_data_exporter.gd # Data export for modding/balancing
├── resources/
│   ├── profiles/
│   │   ├── player_archetype_profile.gd # Custom Resource class
│   │   ├── resonator_editor.tres      # S-class profile
│   │   ├── biomech_active.tres        # Σ-class profile
│   │   └ resonator_analyst.tres       # P-class profile
│   ├── runes/
│   │   └ rune_data.gd                # Custom Resource class
│   ├── items/
│   │   └ item_data.gd                # Custom Resource class
│   ├── ai/
│   │   └ ai_weights_resource.gd      # AI plasticity weights
├── assets/
│   ├── shaders/
│   │   ├── resonance_effect.shader   # Rune activation visual
│   │   ├── perception_mode.shader    # ℘ mode overlay
│   │   ├── overheating_overlay.shader # Body temp warning
│   │   ├── bioluminescent_flora.shader # Dark flora + glow
│   │   ├── quantum_tunnel.shader     # Tunnel creation effect
│   ├── models/  (placeholder — use simple Godot CSG shapes)
│   ├── textures/
│   ├── sounds/
│   └ fonts/
├── data/
```

### Key Mechanics

1. **Аксиома Вериса (V = -k·ΔH)** — No mana, only ATP + oxygen consumption. Overuse → Ruinic Echo → overheating (40.8°C) → HP damage.

2. **1.4g Gravity** — Constant 13.72 m/s². Fall >2m = instant death. Jump modified. Σ archetype adapted.

3. **POLER System** — ℘ (Perception/Alt key), O (Image/Rune crafting), L (Logic/causal geometry), ε (Energy/adaptive AI), R[n] (No Excuses/spontaneous refraction).

4. **10 Fundamental Runes** — Tet, Oro, Ka, Vei, Nul, Sol, Zen, Ari, Dyn, Mir. 15+ crafting combos.

5. **Three Endings** — Stabilization, Rewrite (g→1.0), Rift (reality fragmentation).

6. **Factions** — Bureau Sterilization (suppressors), Shadows (assassins), Coral Cartel, Lex Synthesis, Architect.

### How to Open

1. Open with Godot 4.7.x
2. Import project
3. Run prologue_zone.tscn as main scene

### Modding

Use `GameDataExporter` to export all game data as JSON. Modify and import as mod data.

# Player Team Guide (Game Output 4 – JRPG Turn-Based Battle)

Engine: Godot 4.7 (GDScript). Style: Mario & Luigi-type battles – **action commands** (timed button presses) boost damage, and both heroes can **dodge/counter** enemy attacks.

## 1. Files

| File | Purpose |
|---|---|
| `scripts/core/fighter.gd` | Base class for *every* combatant (heroes and enemies): HP/ATK/DEF/SPD, `take_damage`, `heal`, `is_alive`, the shared **RNG damage formula** `calc_damage`, signals. |
| `scripts/core/attack_data.gd` | `AttackData` resource: name, description, kind (DAMAGE/HEAL/BROS), target type, power, hits, timing-window length, ring colour. The battle menu reads this. |
| `scripts/core/action_command.gd` | The timing mini-game (shrinking ring). Returns a rating: MISS / GOOD / GREAT / PERFECT. |
| `scripts/player/hero.gd` | `Hero` – performs attacks and handles incoming enemy attacks. |
| `scripts/player/kai.gd`, `mira.gd` | The two party members (stats + attack list, button Z / X). |
| `scripts/test/*`, `scenes/test/player_test.tscn` | Sandbox with a dummy enemy so the player side can be tested without the battle system. |

## 2. How the timing system works (`ActionCommand`)
1. `start(action, duration, colour)` shows a ring that shrinks toward a target circle. The sweet spot is at 75% of `duration`.
2. Pressing the hero's button scores by distance from the sweet spot: ≤0.05 s PERFECT, ≤0.11 s GREAT, ≤0.22 s GOOD, otherwise (or no press) MISS.
3. It emits `finished(rating)`. `run()` is an `await`-able shortcut.
4. The same node is used for attacking **and** defending. Damage multiplier: MISS ×0.5, GOOD ×1.0, GREAT ×1.25, PERFECT ×1.5.

## 3. Commands (6 distinct effects)
| Hero | Command | Effect |
|---|---|---|
| Kai | Jump Strike | One heavy timed hit |
| Kai | Fire Hammer | 3 weaker hits, each needs its own timing |
| Kai + Mira | Bros Smash | Both heroes time their own button; both Great+ = ×1.2 teamwork bonus |
| Mira | Quick Slash | 2 fast hits |
| Mira | Mend | Heals an ally; healing scales with timing |
| Both | Dodge / Counter | Defensive – see below |

## 4. Defence (`Hero.receive_attack`)
When an enemy attacks, the target gets a dodge window on **their** button, and the partner gets an **assist** window on **theirs**.
- Target rating: MISS full damage · GOOD ×0.6 · GREAT ×0.3 · PERFECT ×0 **and counter-damage** to the attacker.
- Partner assist ≥ GOOD: extra ×0.85 reduction.

## 5. RNG (`Fighter.calc_damage`)
- 5 % whiff chance
- ±10 % damage roll
- Crit chance 8 % (33 % on PERFECT), ×1.5 damage

## 6. Unique mechanic
Action commands + dual-hero counters (timing-based offence and defence, plus the cooperative Bros attack).

## 7. Hooking into the battle system (for teammates)
```gdscript
# Battle handler – a hero's turn
await hero.perform_attack(attack_data, target)   # target = Fighter (enemy, or ally for Mend)
# hero.attacks is an Array[AttackData] for building the command menu

# Enemy – attacking a hero
await target.receive_attack(self, power)         # returns {damage, rating, countered}
```
- Enemies should `extends Fighter` (see `scripts/test/dummy_enemy.gd`).
- Set `hero.partner` for both heroes (`kai.partner = mira`, and vice versa).
- Connect each fighter's `log_message(text)` signal to the UI text box, `hp_changed` to HP bars, `died` for win/lose checks.
- Heroes and enemies must share the same parent node (tween positions are local).

## 8. Adding a new command
In `kai.gd`/`mira.gd` `_setup_attacks()` add `AttackData.make(name, desc, kind, power, hits, target, colour)`.

## 9. Testing
Run `scenes/test/player_test.tscn`. Keys: 1–5 commands, Space/Enter make the dummy attack Kai/Mira, Z/X are the hero buttons. Headless scripted run: `Godot --headless --path . res://scenes/test/player_test.tscn -- --autotest`.

## 10. Submission note
Zip only relevant code (`scripts/core`, `scripts/player`) as `Surname1_Surname2_Surname3_GameOutput4.zip`.

## 11. Art credits
- Kai: *Fantasy Warrior* by LuizMelo (CC0) � `assets/player/kai/`
- Mira: *Huntress 2* by LuizMelo (CC0) � `assets/player/mira/`
Sprites are built in `Fighter.setup_sprites()` from horizontal sheets (frame = sheet height); each hero's `_ready()` lists its sheets, frame counts, and a "feet" pixel so animations sit on the ground.

- Font: *Peaberry Base* (SIL OFL 1.1) – `assets/fonts/` (only PeaberryBase.ttf + OFL.txt kept)
- Popups (`scripts/core/popup_text.gd`): rating text (PERFECT gold, GREAT blue, GOOD white, MISS red) and damage/heal numbers over heads.

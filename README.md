# ELDORIA: CLASH OF LEGENDS

A standalone, browser-based 3D arena fighter built with Three.js. All fighters, props, effects, and arenas are original procedural geometry; the project does not reuse the previous open-world project.

## Run

```sh
npm install
npm run dev
```

Open the Vite URL in a modern desktop or mobile browser. On mobile, play in landscape for the intended layout.

## Controls

- **PC:** WASD move, mouse rotate camera (click the arena to capture the pointer), wheel adjusts camera distance, left/right mouse light/heavy, Q guard, Shift dodge/run, Space jump, E/R/F skills, G ultimate, Tab toggles target lock, Escape pauses.
- **Touch:** left virtual stick moves; right-side buttons attack, guard, dodge, jump, and use skills. Touch buttons can be pressed while the stick is held.

Choose Lyra or Draeven, an arena, versus AI or training, and one of three AI difficulties from the opening menu. The match includes stamina, attack recovery, combo timing, active hit checks, guard damage reduction, dodge invulnerability, knockback, stun, cooldowns, timer, results, rematch, and pause.

## Scope notes

This is a playable prototype, not a production game export. Fighter visuals are assembled from articulated procedural mesh parts and animated procedurally; they are not sculpted, textured character assets with authored skeletal animation clips. Lighting/shadows and the visual detail are tuned for a browser prototype, not high-end realistic fidelity. The included renderer targets WebGL; Android support depends on the browser/GPU. Low/Medium/High presets, remappable controls, sound, and multiplayer are not implemented. Validate on target devices before release.

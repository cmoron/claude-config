# Debugging / tuning an xdyn model's dynamics

When a simulated agent (surface craft, AUV, USV, towed sensor, sailboat, drone…)
diverges, spins, drifts, or "moves wrong", triage the cause in this order — do NOT jump
straight to re-tuning coefficients.

## 0. First question: real-world difficulty, or model defect?

LOTUSim exists so an agent's OWN algorithm (a trajectory planner, a rule-based skipper, a
guidance law) solves the hard parts. Before "fixing" the model, decide which side of the
wall the problem is on:

- **Real-world difficulty → leave it; it's the algorithm's job.** If the maneuver is
  genuinely hard on real water (tacking a sailboat, a tight turn at speed, holding station
  in current), the sim SHOULD be hard. Making the model trivial defeats the purpose.
- **Model defect → fix the model.** Signs: the behavior is unphysical for a real vehicle
  of these specs, or the coefficients aren't a self-consistent vehicle (arbitrary/ESTIMATED
  values fighting each other — e.g. a damping term cranked up to hide something). A real,
  well-designed hull both holds course AND maneuvers; if the model can't do both at once,
  that's calibration, not a real wall.

Discriminator: would a competent operator / a textbook control law succeed on the REAL
vehicle? Yes but the sim fails → model defect. (Often it's BOTH — under-calibration makes
a real-but-hard task even harder; separate the two.)

## 1. Numerical artifact (check FIRST)

Divergence (NaN, position → ∞) or an apparent uncommanded spin is OFTEN the integrator, not
the physics. Replay the SAME case varying only solver/step: `-s rk4 --dt 0.005`, `--dt
0.001`, `-s rkck` (adaptive). If it stabilises → it was the step size (the model is stiff).

- Standalone xdyn: `rkck` (adaptive) is fine.
- **Co-sim `xdyn-for-cs`: `rkck` is FORBIDDEN** — the step server needs a monotonic clock;
  adaptive solvers back-track in time → `history must be recorded in a strictly increasing order`.
  Use `rk4`, and **decouple the integration step from the comm rate**: the launch flag `--dt` is
  the solver's REAL fixed step, while the `Dt` in each websocket message is only the co-sim horizon
  to advance. When `Dt_message > --dt`, xdyn SUB-STEPS internally (effective step =
  `min(--dt, Dt_message)`). So for a stiff / lightly-damped model, launch with a FINE `--dt`
  (e.g. `0.001`) and still communicate/control at a coarser rate (e.g. `Dt = 0.02`): full
  fine-step numerical stability without a websocket round-trip per integration step. (In a full
  LOTUSim world: launch `xdyn-for-cs --dt <fine>`; the gz plugin sends `Dt` at the render rate.)
  A fine `--dt` costs ~`1/--dt` wall-clock — negligible for one vessel. If even a fine fixed step
  still diverges, the cause is PHYSICAL (a real instability), not the integrator → DE-STIFFEN
  (softer restoring / more added mass) rather than bake a damping crutch that hides it and
  distorts the physics.

## 2. Measurement artifact (check SECOND)

A wrong number often comes from HOW you measured:

- **Open-loop (fixed actuators) is contaminated** — a free vehicle yaws/drifts, so the
  "steady state" you read isn't the regime you meant. To measure a steady regime, hold the
  state with a controller (a **closed loop**).
- **Speed over ground ≠ progress.** It doesn't tell "going where you point" from "drifting".
  Measure **made-good projected onto the intended direction** (negative = going backwards).

Closed-loop probe without gz/ROS: `xdyn-for-cs` is a step server, so a small websocket
client (read state → your control law → send command → step) can drive one vehicle in
isolation for tuning. Protocol + vessel_cmd JSON: `run-and-verify.md`.

## 3. Convention (never infer from a noisy run)

Frame/sign conventions (flow direction, actuator sign, NED/ENU) must be **calibrated**, not
guessed from an open-loop trace: fix one variable, sweep the other, read the extremum.
Example (sailboat): `direction` in `uniform wind`/`current` = bearing the flow blows TOWARD
(N0 E90); a control surface can be mounted sign-inverted (controller needs `sign=-1`) —
both pinned by holding a fixed heading and sweeping the wind, min-made-good = flow on the nose.

## Paths

Ad-hoc tuning harnesses (websocket probe, sweep scripts) are session scratch — keep them OUT
of the deliverable repos (model → core `assets/`, controller → generic-scenario
`src/agents/`). Never hard-code a scratch path as canonical.

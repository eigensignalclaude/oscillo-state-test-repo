# Oscillo — Circuit Agent Primer

**Everything you need to read, modify, and simulate circuits in this repo.**

This repo holds the circuit state for Oscillo, a browser-based schematic editor. The circuit is `baked_state.json` on the `user` branch. A live web editor at `oscillo-ai-collab.vercel.app` reads and writes this file. You work alongside it.

---

## Quick Start (Python)

```python
import json

with open("baked_state.json") as f:
    circuit = json.load(f)

# List all elements
for name, el in circuit["elements"].items():
    etype = el["etype"]
    # Pin references contain ".suffix" — strip to get net names
    nets = {k: el[k].split(".")[0] for k in el if isinstance(el.get(k), str) and "." in el[k]}
    print(f"{name}: {etype}  {nets}  value={el.get('value')}")

# Get model parameters
models = circuit.get("models", {})
if "2N5179" in models:
    print(f"2N5179 BF = {models['2N5179']['parameters']['BF']}")
```

---

## JSON Format (v3)

### Top-level structure

```json
{
  "version": "3.0",
  "title": "HP 10811A OCXO",
  "nodes": { ... },
  "elements": { ... },
  "wires": [ ... ],
  "models": { ... },
  "mutual_inductances": [ ... ],
  "initial_conditions": [ ... ],
  "_editor": { ... }
}
```

**You care about:** `elements`, `models`, `initial_conditions`, `mutual_inductances`.  
**You can ignore:** `nodes`, `wires`, `_editor` — those are layout/UI data.

### Elements

Dict keyed by name. Pin connections are top-level fields using dot-suffixed node references.

```json
{
  "R1":  { "etype": "R", "value": 1000, "p": "net13.a", "n": "net14.a" },
  "C5":  { "etype": "C", "value": 1.5e-9, "p": "net13.b", "n": "0.a" },
  "Q1":  { "etype": "Q", "c": "net26.a", "b": "net31.b", "e": "net34.a", "device_ref": "2N5179" },
  "Y1":  { "etype": "Y", "p": "net22.a", "n": "net24.b", "parameters": { "C0": 2.8e-12, "arms": [...] } },
  "VR3": { "etype": "VR", "value": 12, "p": "net7.a", "n": "0.c" },
  "T1":  { "etype": "T", "p1": "net28.a", "p2": "net29.a", "s1": "net30.a", "s2": "net31.a",
            "parameters": { "L_primary": 6e-6, "ratio": 0.333, "coupling": 0.999 } }
}
```

**To get SPICE net names:** strip the `.suffix` from pin references. `"net13.a"` → `"net13"`. `"0.c"` → `"0"` (ground).

### Element types and pin schemas

| `etype` | Description | Pins | `value` | Notes |
|---------|-------------|------|---------|-------|
| `R` | Resistor | `p, n` | Ω | |
| `C` | Capacitor | `p, n` | F | |
| `L` | Inductor | `p, n` | H | `parameters.RS` for winding resistance |
| `D` | Diode | `a, k` | — | Uses `device_ref` |
| `Q` | BJT | `c, b, e` | — | Polarity from model `model_type` |
| `Y` | Crystal (XTAL) | `p, n` | — | See Crystal section |
| `D_vcap` | Varicap | `a, k` | F (C₀) | Uses `device_ref` |
| `V` | Voltage source | `p, n` | V (DC) | |
| `VR` | Voltage rail | `p, n` | V (DC) | `n` is virtual. Backend: DC source to ground. |
| `T` | Transformer | `p1, p2, s1, s2` | — | See Transformer section |
| `G` | Ground marker | `p, n` | — | `n` is virtual. `p` connects to grounded net. |

### Models

Device parameters stored as templates in `models`, referenced by `device_ref` on elements. SPICE naming conventions (uppercase).

```json
{
  "models": {
    "2N5179": {
      "model_type": "NPN",
      "parameters": { "IS": 6.928e-17, "BF": 240, "NF": 1, "VAF": 100, ... }
    }
  }
}
```

### Crystal (`Y`)

Multi-arm BVD model. `Lm` is **never stored** — derive it as `1/((2πf)²·Cm)`. `Q` = `1/(2πf·Cm·Rm)`.

```json
"Y1": {
  "etype": "Y", "p": "net22.a", "n": "net24.b",
  "parameters": {
    "C0": 2.8e-12,
    "arms": [
      { "name": "Fundamental", "f": 3333333, "Rm": 25, "Cm": 1.706e-15 },
      { "name": "3rd overtone", "f": 10000000, "Rm": 220, "Cm": 1.9e-16 }
    ]
  }
}
```

### Transformer (`T`)

`L_secondary` is **never stored** — derive it as `L_primary · ratio²`.

```json
"T1": {
  "etype": "T",
  "p1": "net28.a", "p2": "net29.a", "s1": "net30.a", "s2": "net31.a",
  "parameters": { "L_primary": 6e-6, "ratio": 0.333, "coupling": 0.999 }
}
```

### Initial conditions

```json
"initial_conditions": [
  { "node": "net26", "value": 10.0, "type": "voltage" },
  { "element": "L5", "value": 0.00171, "type": "current" }
]
```

---

## HP 10811 Circuit Models

The current circuit is the HP 10811A OCXO. Complete SPICE model data:

**2N5179 (NPN)** — used by Q1, Q2, Q3:
```
.MODEL 2N5179 NPN IS=6.928e-17 BF=240 NF=1 VAF=100 IKF=0.02203
+ ISE=0 NE=1.177 BR=1.176 NR=1 ISC=0 NC=2
+ RB=10 RC=4
+ CJC=8.931e-13 MJC=0.3017 VJC=0.75 FC=0.5
+ CJE=9.398e-13 MJE=0.3453 VJE=0.75
+ TF=1.411e-10 TR=1.588e-9
+ ITF=0.27 VTF=10 XTF=30
+ XTI=3 EG=1.11 XTB=1.5
```

**Q9_RF (NPN)** — used by Q4:
```
.MODEL Q9_RF NPN IS=2e-14 BF=300 NF=1 VAF=75 IKF=0.15
+ ISE=0 NE=1.5 BR=1 NR=1 ISC=0 NC=2
+ RB=10 RC=4 RE=0
+ CJC=4.7e-12 MJC=0.3 VJC=0.75 FC=0.5
+ CJE=5e-12 MJE=0.33 VJE=0.75
+ TF=1.96e-10 TR=1e-8
+ XTI=3 EG=1.11
```

**2N6429A (NPN)** — used by Q5:
```
.MODEL 2N6429A NPN IS=6.031e-15 BF=559 NF=1 VAF=996 IKF=0.1878
+ ISE=0 NE=1.5 BR=44 NR=1 ISC=0 NC=2
+ RB=10 RC=4
+ CJC=2.136e-11 MJC=0.3843 VJC=0.75 FC=0.5
+ CJE=5.561e-11 MJE=0.3834 VJE=0.75
+ TF=5.161e-10 TR=7.215e-8
+ ITF=0.5 VTF=4 XTF=6
+ XTI=3 EG=1.11 XTB=1.5
```

**5082-2800-RevB (D)** — used by D1, D2:
```
.MODEL 5082-2800-RevB D IS=2.2e-9 RS=25 N=1.08 BV=75 IBV=1e-4
+ CJO=1.6e-12 VJ=0.6 M=0.5
+ EG=0.4 XTI=2 TT=1e-10
```

**default (D)** — used by DV1 (AGC varicap bias):
```
.MODEL default D CJO=1e-10
```

---

## SPICE ↔ HB Parameter Translation

For agents working with the harmonic balance engine:

```python
BJT_PARAM_MAP = {
    "BF":  lambda v: ("alpha_F", v / (v + 1)),
    "BR":  lambda v: ("alpha_R", v / (v + 1)),
    "IS":  "I_S",
    "VJE": "phi_E",     "MJE": "M_E",
    "VJC": "phi_C",     "MJC": "M_C",
    "CJE": "C_jE0",     "CJC": "C_jC0",
    "TF":  "tau_F",     "TR":  "tau_R",
    "KF":  "K_F",       "AF":  "A_F",
    "RB":  "R_B",       "RC":  "R_C",       "RE":  "R_E",
    "VAF": "V_AF",      "VAR": "V_AR",
    "NF":  "n_F",       "NR":  "n_R",       "FC":  "F_C",
}
```

---

## Simulation Results Format

If you produce simulation results, write them as JSON files to the `user` branch.

**SPICE DC Operating Point** (`spice_results.json`):
```json
{
  "analysis": "dc_op",
  "success": true,
  "node_voltages": {"net7": 20.0, "net26": 10.1, "net31": 4.8, "net34": 4.1},
  "branch_currents": {"VR3": -0.028}
}
```

**SPICE Transient** (`spice_results.json`):
```json
{
  "analysis": "transient",
  "success": true,
  "time": [0, 1e-9, 2e-9],
  "signals": {"V(net26)": [10.1, 10.0], "V(net31)": [4.8]}
}
```

**HB Phase Noise** (`hb_results.json`):
```json
{
  "analysis": "hb_phase_noise",
  "success": true,
  "frequency": 10000000.1,
  "f_offsets": [1, 10, 100, 1000, 10000],
  "L_f_dBc": [-60, -90, -120, -140, -155],
  "contributions": {
    "Q1_shot_IC": [-65, -95, -125, -145, -160],
    "Y1_Rm_thermal": [-70, -100, -130, -150, -165]
  },
  "floquet_multipliers": [0.9998],
  "adev": {
    "tau": [0.01, 0.1, 1, 10, 100],
    "sigma_y": [1e-11, 3e-12, 1e-12, 3e-13, 1e-13]
  }
}
```

---

## Git Workflow

**Read the circuit:**
```bash
git checkout user && git pull origin user
# baked_state.json is now current
```

**Modify the circuit (requires user review in the editor):**
```bash
git checkout -b agent/your-description
# edit baked_state.json
git add baked_state.json
git commit -m "Descriptive message about what changed and why"
git push origin agent/your-description
```
The editor polls for `agent/*` branches and shows a diff for the user to accept or reject.

**Write simulation results (no review needed):**
```bash
git checkout user && git pull origin user
# write spice_results.json or hb_results.json
git add spice_results.json
git commit -m "SPICE results: DC OP"
git push origin user
```

**Never force-push. Never push directly to `user` for circuit modifications.** Simulation results go to `user` directly; circuit changes go to `agent/*` for review.

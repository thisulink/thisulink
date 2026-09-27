# THISULINK™ Plantar Diagnostic Platform — Hardware Specification

| | |
|---|---|
| **Document** | HW-SPEC-001 |
| **Subsystem** | Plantar Shear-Wave Elastography & Thermography Platform |
| **Wire contract** | [BLE_SPECIFICATION.md](BLE_SPECIFICATION.md) |
| **Status** | Design specification — see §9 for build status |

---

## 1. Clinical purpose

Diabetic foot ulceration is preceded by changes that are invisible on
inspection: the plantar soft tissue stiffens as collagen glycates, and a
developing inflammatory focus raises local temperature before any break in the
skin. Both are measurable non-invasively, and both are missed by a visual
screening exam.

The platform measures two independent physical signals at the same site in the
same sitting:

| Signal | Physical basis | Clinical meaning |
|---|---|---|
| **Shear-wave speed / Young's modulus** | Surface wave propagation through plantar soft tissue | Tissue stiffening from advanced glycation end-product accumulation |
| **Contralateral thermal asymmetry ΔT** | Non-contact far-infrared emission | Localised inflammation preceding ulceration |

Neither measurement diagnoses. Together they stratify risk, and the platform's
job is to make that stratification reproducible enough that a health worker
with a week of training produces the same numbers as a clinician.

---

## 2. Architecture

```
                 THISULINK PLANTAR PLATFORM
    ┌──────────────────────────────────────────────────────┐
    │                                                      │
    │   ┌────────────┐         PLANTAR SURFACE             │
    │   │  MLX90621  │  ◄── non-contact FIR, 16×4          │
    │   │  16×4 FIR  │      64 pixels, contralateral ΔT    │
    │   └────────────┘                                     │
    │                                                      │
    │   ═══════════════════════════════════════════        │
    │        ▲             ▲                ▲              │
    │        │             │                │              │
    │   ┌────┴────┐   ┌────┴────┐     ┌─────┴─────┐        │
    │   │   VCA   │   │ ADXL355 │     │  ADXL355  │        │
    │   │ 10–300Hz│   │ pickup 1│     │  pickup 2 │        │
    │   │ 0.100 N │   │ x₁=105mm│     │  x₂=145mm │        │
    │   └─────────┘   └─────────┘     └───────────┘        │
    │                 └──── Δx = 40 mm baseline ────┘      │
    │                                                      │
    │   ┌──────────────────────────────────────┐           │
    │   │  TAL221 load cell  →  HX711 24-bit   │           │
    │   │  preload interlock 1.40 – 1.60 N     │           │
    │   └──────────────────────────────────────┘           │
    │                                                      │
    │   ┌──────────────────────────────────────┐           │
    │   │  MCU · BLE 5.0 · GATT 0xFFE0         │           │
    │   │  73-byte frame @ 0xFFE1 (notify)     │           │
    │   └──────────────────────────────────────┘           │
    └──────────────────────────────────────────────────────┘
                              │
                              ▼  BLE 5.0
                   Clinical Diagnostic Suite (tablet)
```

---

## 3. Excitation — voice coil actuator

| Parameter | Value |
|---|---|
| Actuator type | Voice coil (VCA), direct-drive |
| Sweep range | **10 – 300 Hz** |
| Dynamic force | **0.100 N** |
| Sweep duration | 200 ms per acquisition |
| Coupling | Medical-grade silicone pad |

The band is chosen for tissue, not convenience. Below ~10 Hz the response is
dominated by bulk limb motion; above ~300 Hz attenuation in soft tissue makes
the second pickup's signal-to-noise unusable across a 40 mm baseline.

Dynamic force is held at 0.100 N — two orders below the static preload — so the
excitation perturbs the tissue without changing the loading state being
measured.

---

## 4. Preload interlock

| Component | Specification |
|---|---|
| Load cell | TAL221 cantilever, 5 kg (≈50 N) capacity |
| ADC | HX711, 24-bit, integrated gain |
| Sample rate | 80 SPS |
| **Valid window** | **1.40 N – 1.60 N** |
| Out-of-window behaviour | Sample flagged, excluded from averaging |
| Wander behaviour | Auto-abort if preload leaves the window mid-sweep |

### Why an interlock rather than a correction

Soft tissue is non-linear and load-dependent: its apparent stiffness rises with
applied force. A shear-wave measurement taken at 2.5 N and one at 1.5 N are not
the same measurement with different noise — they are measurements of different
mechanical states.

Two options exist: measure the force and correct for it, or constrain the force
and refuse to measure outside the constraint. The platform constrains, because
correction requires a per-patient tissue model the device does not have. A
rejected scan costs thirty seconds. A silently load-biased scan enters the
clinical record and is indistinguishable from a real finding.

### Tare procedure

The load cell is zeroed via the `TARE` command (§3.2 of the BLE specification)
at rest before each encounter, compensating for platform orientation and
accumulated mechanical drift.

---

## 5. Surface wave sensing

| Parameter | Value |
|---|---|
| Sensors | 2 × Analog Devices ADXL355, low-noise triaxial MEMS |
| Pickup 1 position | x₁ = **105 mm** from actuator axis |
| Pickup 2 position | x₂ = **145 mm** from actuator axis |
| Baseline | **Δx = 40 mm** |
| Sampling | Synchronous, shared clock |

### Phase velocity derivation

Shear-wave speed is computed from the phase difference between the two pickups
at each sweep frequency:

> **cₛ = ω · Δx / Δφ**

where ω is angular excitation frequency, Δx the 40 mm baseline, and Δφ the
measured phase delay.

Young's modulus follows from the shear-wave speed under a near-incompressible
soft-tissue assumption:

> **E ≈ 3ρcₛ²**

with ρ taken as soft-tissue density.

### Why two sensors rather than time-of-flight

A phase-difference measurement across a **fixed, known** baseline is
insensitive to the absolute trigger instant and to actuator latency, both of
which drift with temperature and mechanical wear. A single-sensor
time-of-flight approach inherits every one of those errors directly into the
reported speed.

The baseline is the one dimension that must not move: Δx appears linearly in
cₛ, so a 1 mm mounting error is a 2.5% systematic error in every reading the
device ever produces. Pickup spacing is therefore fixed in the moulded
housing, not adjustable.

---

## 6. Thermal mapping

| Parameter | Value |
|---|---|
| Sensor | **Melexis MLX90621**, far-infrared thermopile array |
| Resolution | **16 × 4 = 64 pixels** |
| Measurement | Non-contact, no thermal loading of the site |
| Field of view | Matched to plantar region of interest |
| **Alert threshold** | **ΔT ≥ 2.2 °C** contralateral asymmetry |

### Contralateral comparison

Absolute plantar temperature varies with ambient conditions, recent activity,
footwear and perfusion — none of which indicate pathology. The clinically
meaningful quantity is the **difference between corresponding sites on the two
feet**, measured in the same session under the same conditions.

The 2.2 °C threshold follows Lavery et al. (2007), which established
contralateral asymmetry at this magnitude as predictive of impending
ulceration. Both feet are imaged in the same encounter; a single-foot capture
cannot produce a valid ΔT and is rejected at the application layer.

### Why a 64-pixel array

A single-point IR thermometer measures wherever it is aimed. An inflammatory
focus is localised, so a point measurement a centimetre away from it reads
normal. The 16×4 array covers the region of interest in one capture, removing
operator aim from the measurement.

---

## 7. Mechanical housing

| Element | Specification |
|---|---|
| Enclosure | 3D-printed PETG |
| Acoustic coupling | Medical-grade silicone interface pad |
| Vibration isolation | Rubberised damping feet |
| Sensor mounting | Rigid, fixed 40 mm pickup baseline |

PETG is specified over PLA for dimensional stability at clinic temperatures and
for its tolerance of repeated surface disinfection.

The damping feet serve the measurement, not comfort: without isolation, the
VCA excitation couples into the examination surface and returns to the pickups
as a structural path parallel to the tissue path, corrupting the phase
difference the entire instrument depends on.

> Complete mechanical engineering CAD models, cross-sectional schematics, and OpenSCAD parametric files: **[cad/README.md](cad/README.md)**.

---

## 8. Interface summary

| Interface | Specification |
|---|---|
| Wireless | Bluetooth Low Energy 5.0 |
| Service | `0xFFE0` |
| Telemetry | `0xFFE1`, notify, 73 bytes |
| Control | `0xFFE2`, write, 4 bytes |
| Frame header | `0x5448` (`"TH"`) |
| Integrity | CRC-8/MAXIM over bytes 0–71 |

Full byte-level contract: **[BLE_SPECIFICATION.md](BLE_SPECIFICATION.md)**.

---

## 9. Implementation status

| Item | Status |
|---|---|
| Mechanical and sensing design | Specified |
| BLE wire contract | Specified, frozen at v1.0 |
| Client-side decoder | Implemented, 18 conformance tests passing |
| Client-side interlock enforcement | Implemented |
| Tissue classification bands | Implemented, unit-tested |
| **Probe firmware** | **Not validated against this document** |
| **End-to-end acquisition on hardware** | **Not yet performed** |

The software half of this interface is complete and tested against the
specification. The specification has not been confirmed against a physical
probe. Section 8 of the BLE specification is the checklist that closes that
gap, and it must be executed on-target before any clinical use.

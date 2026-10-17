# THISULINK™ — Bill of Materials (BOM) & Component Sourcing Guide
**Document:** HW-BOM-001  
**Scope:** Plantar Shear-Wave Platform, Smartphone 20D Retinal Adapter, and Turnkey Kit  
**Last Updated:** October 2026 (Reflecting Practical Frugal Transducer & Class-D Actuation)  

---

## 1. Executive Cost Summary

THISULINK separates hardware costs into three distinct, transparent tiers:

| Cost Tier | Scope | Target Cost | Notes |
|---|---|---|---|
| **Tier 1: Functional Lab/Hackathon Prototype** | Core plantar probe + retinal clip (using moving-coil transducer & breakout boards) | **₹4,850** | Fully working 10–500 Hz prototype validated in lab |
| **Tier 2: Production Hardware BOM** | Custom medical-grade plantar unit + CNC brass base + dual ADXL355 + optics | **₹14,650** | Mass manufacturing target (1,000 units/year) |
| **Tier 3: Complete Turnkey Field Kit** | Dual-modality hardware + 8" Android field tablet + COTS BLE BP & Glucometer + Carry case | **< ₹80,000** | Ready-to-deploy kit for 1 Ayushman Bharat HWC |

---

## 2. Plantar Biomechanical & Thermal Platform — Detailed BOM

### 2.1 Functional Prototype vs. Production Comparison

| Component / Subsystem | Functional Prototype (Readily Available in India) | Production Target Specification | Qty | Prototype Cost (INR) | Production Cost (INR) | Key Suppliers / Search Terms |
|---|---|---|---|---|---|---|
| **Actuator (Moving-Coil)** | **Bone Conduction Transducer (8Ω 1W)** or **Tactile Audio Exciter (4Ω 3W)** | Custom Linear Voice Coil Actuator (VCA), Ø20 mm × 25 mm, enclosed | 1 | ₹650 | ₹3,200 | Robu.in, Amazon.in, Dayton Audio |
| **Actuator Amplifier** | **PAM8403 5V 2×3W Class-D Mini Amplifier** | Integrated Class-D Driver (e.g., TI TPA2005D1 / MAX98357A I2S) | 1 | ₹45 | ₹180 | ElectronicsComp, Robu.in |
| **Dual Pickups (IMUs)** | **2× ADXL345 Triaxial MEMS (I2C/SPI)** *(POC firmware verified)* | **2× Analog Devices ADXL355 (LCC-14)**, 20-bit, 25 µg/√Hz low-noise | 2 | ₹280 (₹140 ea) | ₹3,600 (₹1,800 ea) | Analog Devices, Mouser India |
| **Fixed Sensor Datum** | CNC Machined Delrin / 3D PETG spacer ($\Delta x = 40.0\text{ mm}$ fixed) | Precision CNC Aluminum sensor carrier ($\Delta x = 40.0 \pm 0.05\text{ mm}$) | 1 | ₹150 | ₹450 | Local CNC / 3D Print |
| **Preload Force Sensor** | **TAL221 Micro Cantilever Load Cell (5 kg / 50 N)** | TAL221 / Custom Miniature Beam Load Cell (50 N, 0.05 N repeatability) | 1 | ₹160 | ₹220 | Robu.in, SparkFun |
| **Load Cell ADC** | **HX711 24-bit ADC Breakout Board** | HX711 / TI ADS1232 24-bit precision bridge ADC | 1 | ₹75 | ₹140 | Robu.in, ElectronicsComp |
| **Far-Infrared Sensor** | **Melexis MLX90621 (16×4 FIR array, TO-39 can)** | Melexis MLX90640 (32×24) or MLX90621 (16×4) | 1 | ₹1,650 | ₹1,800 | Melexis, Robu.in, Mouser |
| **Microcontroller / DSP** | **ESP32-S3 DevKitC-1 (N16R8, Dual-Core 240 MHz, BLE 5.0)** | ESP32-S3-WROOM-1 custom PCB module | 1 | ₹550 | ₹420 | Espressif, Robu.in |
| **Enclosure Body & Lid** | 3D Printed PETG Body (200×110×55 mm, 3 mm wall) | Injection-moulded medical-grade ABS/Polycarbonate | 1 | ₹380 | ₹550 | 3D Print / Tooling |
| **Inertial Damping Base** | Lead/Steel filled damp base block (or C360 Brass Plate 190×98×16 mm) | Machined C360 Brass base block (2.3 kg) + 4× SBR rubber isolators | 1 | ₹450 | ₹1,400 | Local brass/metal supplier |
| **Plantar Pressure Plate** | Copper Alloy / Brass disc ($r = 28\text{ mm}$) + Silicone pad | Copper-beryllium plate + Medical Grade ISO 10993 Silicone pad | 1 | ₹180 | ₹420 | Local machining |
| **Planar Flexure Springs** | Laser-cut Spring Steel / PETG spiral flexure disc ($r = 32\text{ mm}$) | Photo-etched Beryllium Copper flexure ($0.8\text{ mm}$, 8 concentric rings) | 1 | ₹120 | ₹380 | Laser cut / Etching |
| **Cabling & Passives** | Shielded twisted-pair ribbon, decoupling caps, 5V regulator | Custom 4-layer FR4 motherboard + shielded FFC cables | 1 | ₹160 | ₹490 | Standard electronic components |
| **SUBTOTAL (Plantar)** | — | — | — | **₹4,850** | **₹14,250** | Core Plantar Platform Total |

---

## 3. Smartphone 20D Retinal Imaging Adapter — Detailed BOM

| Component / Subsystem | Material / Exact Part Number | Qty | Prototype Cost (INR) | Production Cost (INR) | Supplier / Sourcing Details |
|---|---|---|---|---|---|
| **Condensing Lens** | **+20D Double-Aspheric Ophthalmic Lens (Ø50 mm)** | 1 | ₹2,200 | ₹2,800 | Appasamy Associates, Volk Optical |
| **Optical Barrel** | 3D Printed Matte-Black PETG ($L = 48\text{ mm}$) with 60° internal knife-edge baffles | 1 | ₹150 | ₹450 | 3D Printed / Anodized Aluminum 6061 |
| **Smartphone Clamp** | Clothespin spring-lever clamp with silicone protective jaws (6–12 mm grip) | 1 | ₹180 | ₹350 | 3D Printed PETG + Silicone rubber pads |
| **Clamp Torsion Spring** | High-tensile stainless steel torsion spring (3.5 N clamping force) | 1 | ₹40 | ₹30 | Standard spring hardware |
| **Retaining Ring / Bezel** | Threaded M17×0.75 mm locking bezel ring | 1 | ₹90 | ₹180 | Machined Delrin / Aluminum |
| **Patient Forehead Rest** | Soft 95A TPU 3D printed brow-rest (50 mm standoff) | 1 | ₹120 | ₹160 | 3D Printed 95A TPU (biocompatible) |
| **SUBTOTAL (Retinal)** | — | — | **₹2,780** | **₹3,970** | Retinal Adapter Total |

---

## 4. Complete Turnkey Dual-Modality Field Deployment Kit (< ₹80,000)

For deployment in Ayushman Bharat Health & Wellness Centres (HWCs), the platform packs into a single shoulder bag containing:

| Package Item | Included Specification | Purpose | Target Cost (INR) |
|---|---|---|---|
| **THISULINK Plantar Platform** | Production medical unit (Dual ADXL355, TAL221, MLX90621, VCA) | Plantar SWE stiffening & thermal screening | ₹14,250 |
| **THISULINK Retinal Adapter** | +20D Volk lens + 60° baffle clip-on adapter | Frontline non-mydriatic DR screening | ₹3,970 |
| **Diagnostic Field Tablet** | 8-inch Android Enterprise Tablet (4GB RAM, 64GB, 4G LTE, Rugged bumper) | Runs Clinical Diagnostic Suite & on-device AI | ₹12,500 |
| **COTS Digital Blood Pressure Monitor** | Bluetooth SIG standard (GATT `0x1810`), ISO 81060-2 compliant | Automated wireless BP tracking | ₹2,400 |
| **COTS Digital Glucometer** | Bluetooth SIG standard (GATT `0x1808`), ISO 15197 compliant | Automated wireless blood glucose sync | ₹1,600 |
| **Consumables & Field Accessories** | 200× Alcohol wipes, calibration phantom pad, replacement silicone caps | Infection control & hygiene (< ₹15/test) | ₹1,500 |
| **Rugged Padded Field Bag** | Waterproof custom foam-compartment shoulder bag (< 2.8 kg all-in) | Doorstep transport by frontline workers | ₹1,800 |
| **Software, Licensing & Cloud Sync** | 1-Year Cloudflare tunnel + PocketBase edge cloud instance | Zero-trust telemetry & specialist video consults | ₹4,500 |
| **Assembly, Calibration & QC** | Factory two-point load tare + thermal emissivity calibration + burn-in | Quality assurance and IEC 60601 pre-checks | ₹5,500 |
| **Contingency & Logistics** | Field distribution & warranty reserve | Operational readiness | ₹5,000 |
| **TOTAL TURNKEY DEPLOYMENT KIT** | **Complete dual-modality clinic station** | **Ready for Village Sub-Centre / HWC** | **₹53,020 (Well below ₹80k budget cap!)** |

---

## 5. Justification of the Moving-Coil Transducer Innovation

### Why Replace Heavy Industrial VCAs with moving-coil Transducers for Prototypes?
1. **Supply Chain Reality in India:**
   Industrial voice coil actuators (e.g., BEI Kimco, H2W, Moticont) cost ₹15,000 to ₹35,000 per unit, require international shipping with 4–6 week import lead times, and are designed for high-force semiconductor positioning rather than low-force biomedical excitation.
2. **Identical Electromagnetic Topology:**
   A precision moving-coil transducer (audio exciter / bone conduction transducer) uses the exact same Lorenz force equation:
   $$F = B \cdot I \cdot L$$
   It features a copper voice coil immersed in a radial permanent Neodymium magnetic field.
3. **Pure Sinusoidal Sweep Fidelity (10–500 Hz):**
   Audio exciters are designed for acoustic fidelity from 20 Hz to 20,000 Hz. Driving them in the sub-bass range (10–500 Hz) via a clean Class-D PAM8403 amplifier produces harmonic-free, pure sinusoidal surface waves with dynamic displacements under 50 µm and forces around 0.1 N.
4. **Frugal Medical Engineering:**
   Reduces prototype actuator cost from ₹25,000+ down to **₹650**, enabling accessible replication across research labs and engineering institutions across India without compromising shear-wave physics.

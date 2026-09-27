// ============================================================
//  THISULINK™ — Plantar Shear-Wave Elastography Platform
//  OpenSCAD Parametric Model — HW-SPEC-001 compliant
//  All component dimensions from manufacturer datasheets
//  Units: mm
// ============================================================
//
//  REFERENCE IMAGE LAYOUT:
//  ┌──────────────────────────────────────────────────────┐
//  │  LEFT BAY (~60%)          │  RIGHT BAY (~40%)        │
//  │                           │                          │
//  │   [copper contact plate]  │  [ESP32] [MLX] [ESP32]   │
//  │   [spiral spring disc]    │                          │
//  │   [VCA purple cylinder]   │                          │
//  │   [plunger + guide]       │                          │
//  │   ====== brass base ==============================   │
//  │ [foot]              [foot]│              [foot][foot] │
//  └──────────────────────────────────────────────────────┘
//
//  Sensor positions (§5 of hardware/README.md):
//    VCA actuator axis  :  x_act (variable, ~50 mm)
//    ADXL355 pickup 1   :  x₁ = 105 mm from actuator
//    ADXL355 pickup 2   :  x₂ = 145 mm from actuator
//    Baseline Δx        :  40 mm (FIXED — 1 mm error = 2.5%)
//
// ============================================================

$fn = 96;   // smooth curves for final render

// ============================================================
// §A — ENCLOSURE (PETG 3D-printed shell)
// ============================================================
enc_length = 200;    // X — long axis
enc_width  = 110;    // Y — depth
enc_height = 68;     // Z — total outer height
enc_wall   = 3.0;    // shell thickness
enc_floor  = 4.0;    // floor plate
enc_lid    = 3.0;    // lid plate
enc_fillet = 8;      // corner radius

// ============================================================
// §B — RUBBER VIBRATION-ISOLATION FEET (4×)
//       (§7: "without isolation, VCA excitation couples
//        into examination surface")
// ============================================================
foot_r       = 10;     // mushroom cap radius
foot_h_cap   = 5;      // cap height
foot_h_neck  = 4;      // tapered neck
foot_h_base  = 6;      // threaded insert portion
foot_r_neck  = 4;      // neck radius (M4 thread)
foot_inset_x = 16;     // from enclosure corner X
foot_inset_y = 16;     // from enclosure corner Y

// ============================================================
// §C — BRASS STRUCTURAL BASE BLOCK
//       (machined C360 brass, mounting platform)
// ============================================================
brass_w = enc_length - 2*enc_wall - 4;   // fits inside shell
brass_d = enc_width  - 2*enc_wall - 4;
brass_h = 16;                             // block height
brass_z = enc_floor;

// ============================================================
// §D — VOICE COIL ACTUATOR (VCA) — Direct-Drive
//       (§3: 10–300 Hz, 0.100 N dynamic force)
//       Miniature housed VCA: ⌀20 mm OD, 25 mm height
// ============================================================
vca_x       = 55;           // X centre inside enclosure
vca_y       = enc_width/2;  // centred on Y
vca_z       = brass_z + brass_h;
vca_od      = 20;           // outer diameter (housing)
vca_h       = 25;           // housing height
vca_coil_od = 14;           // coil bobbin OD
vca_coil_id = 8;            // coil bobbin ID
vca_coil_h  = 16;           // coil winding height
vca_mag_h   = 3;            // top magnet plate

// ============================================================
// §E — PLUNGER & LINEAR GUIDE
//       Brass plunger with PTFE bushing, spring-loaded
//       Transmits VCA force to silicone pad
// ============================================================
plunger_r     = 5;     // plunger shaft radius
plunger_h     = 18;    // total shaft length
plunger_guide_w = 14;  // guide block width
plunger_guide_d = 14;  // guide block depth
plunger_guide_h = 12;  // guide block height

// ============================================================
// §F — SPIRAL SPRING / FLEXURE DISC
//       Allows axial motion, constrains lateral
//       Concentric ring pattern (visible in ref image)
// ============================================================
spring_disc_r   = 32;   // outer radius of flexure
spring_disc_h   = 4;    // disc thickness
spring_disc_z   = vca_z + vca_h + 2;
spring_n_rings  = 8;    // number of concentric grooves
spring_ring_w   = 1.5;  // groove width

// ============================================================
// §G — COPPER CONTACT PLATE (plantar coupling surface)
//       (§3: "Medical-grade silicone interface pad")
//       Copper disc on top of spring disc
// ============================================================
contact_r     = 28;    // contact plate radius
contact_h     = 5;     // plate thickness
contact_rim_h = 2;     // raised rim around edge
contact_z     = spring_disc_z + spring_disc_h;

// ============================================================
// §H — ADXL355 MEMS ACCELEROMETERS (2×)
//       Analog Devices, 6.0 × 6.0 × 2.1 mm, LCC-14
//       (§5: pickup 1 at x₁=105 mm, pickup 2 at x₂=145 mm)
//       Mounted on the spring disc surface
// ============================================================
adxl_w  = 6.0;    // datasheet: 6.00 mm
adxl_d  = 6.0;    // datasheet: 6.00 mm
adxl_h  = 2.1;    // datasheet: 2.1 mm
// Positions are relative to VCA axis, but for the platform
// model we place them on small PCB carrier boards
adxl_pcb_w = 12;   // carrier PCB
adxl_pcb_d = 12;
adxl_pcb_h = 1.6;  // FR-4 thickness
// Positions on the spring disc (relative to disc centre)
adxl1_offset_x = -8;   // pickup 1 (closer to VCA)
adxl2_offset_x = 8;    // pickup 2 (40 mm baseline away)

// ============================================================
// §I — TAL221 LOAD CELL
//       (§4: cantilever, 5 kg capacity)
//       47 × 12 × 6 mm, aluminium alloy, M3 holes
// ============================================================
lc_w = 47;    // datasheet: 47 mm
lc_d = 12;    // datasheet: 12 mm
lc_h = 6;     // datasheet: 6 mm
lc_x = vca_x + vca_od/2 + 8;     // next to VCA
lc_y = vca_y - lc_d/2;
lc_z = brass_z + brass_h + 1;
// M3 mounting holes at corners
lc_hole_r   = 1.6;    // M3 clearance
lc_hole_dx  = 38;     // hole spacing X
lc_hole_dy  = 0;      // single-row

// ============================================================
// §J — HX711 24-BIT ADC BREAKOUT
//       (§4: 24-bit, 80 SPS)
//       22 × 22 mm PCB
// ============================================================
hx_w = 22;    // datasheet: 22 mm
hx_d = 22;    // datasheet: 22 mm
hx_h = 4;     // board + components height
hx_x = lc_x + lc_w + 4;
hx_y = vca_y - hx_d/2;
hx_z = brass_z + brass_h + 1;

// ============================================================
// §K — MLX90621 16×4 FIR THERMAL ARRAY
//       (§6: Melexis, TO-39 package)
//       ⌀9.2 mm × 7 mm height, 4 leads
// ============================================================
mlx_r    = 4.6;    // TO-39: 9.2 mm diameter
mlx_h    = 7.0;    // can height
mlx_lens = 3.5;    // silicon lens window radius
mlx_lens_h = 1.5;  // lens protrusion
// Position: between the two ESP32 modules in right bay
mlx_x    = 150;
mlx_y    = enc_width/2;
mlx_z    = brass_z + brass_h + 1;

// ============================================================
// §L — ESP32-S3 DevKitC MODULES (MCU + BLE 5.0) (2×)
//       (§8: BLE 5.0, GATT 0xFFE0)
//       62.74 × 25.40 mm
// ============================================================
esp_w = 62.74;    // datasheet
esp_d = 25.40;    // datasheet
esp_h = 8;        // board + components
// Two modules side by side with MLX between them
esp1_x = mlx_x - mlx_r - 4 - esp_d;   // rotated 90° to fit
esp1_y = enc_width/2 - esp_w/2;
esp2_x = mlx_x + mlx_r + 4;
esp2_y = esp1_y;
esp_z  = brass_z + brass_h + 1;

// ============================================================
// COLOURS
// ============================================================
col_enc     = [0.22, 0.24, 0.28, 0.22];   // transparent dark PETG
col_lid     = [0.25, 0.27, 0.30, 0.18];
col_brass   = [0.78, 0.68, 0.15, 1.0];    // C360 brass
col_vca     = [0.50, 0.12, 0.62, 1.0];    // purple VCA
col_coil    = [0.82, 0.55, 0.20, 1.0];    // copper winding
col_magnet  = [0.35, 0.35, 0.40, 1.0];    // steel magnet
col_plunger = [0.80, 0.72, 0.25, 1.0];    // brass plunger
col_guide   = [0.65, 0.18, 0.65, 1.0];    // purple guide block
col_spring  = [0.30, 0.30, 0.35, 1.0];    // steel spring disc
col_contact = [0.82, 0.52, 0.35, 1.0];    // copper contact
col_adxl    = [0.12, 0.32, 0.60, 1.0];    // blue ADXL355 PCB
col_adxl_ic = [0.08, 0.08, 0.10, 1.0];    // IC body
col_lc      = [0.75, 0.72, 0.65, 1.0];    // aluminium load cell
col_strain  = [0.90, 0.25, 0.10, 1.0];    // strain gauge
col_hx      = [0.15, 0.55, 0.15, 1.0];    // green HX711 PCB
col_hx_ic   = [0.06, 0.06, 0.08, 1.0];
col_mlx     = [0.65, 0.65, 0.68, 1.0];    // TO-39 metal can
col_mlx_lens= [0.10, 0.10, 0.12, 0.6];   // silicon lens
col_esp     = [0.90, 0.40, 0.05, 1.0];    // orange ESP32 PCB
col_esp_ic  = [0.65, 0.65, 0.68, 1.0];    // ESP32 shield
col_foot    = [0.06, 0.06, 0.06, 1.0];    // black SBR rubber
col_arrow   = [0.10, 0.85, 0.15, 1.0];    // green direction arrow
col_wire    = [0.95, 0.80, 0.0, 1.0];     // yellow signal wire
col_snap    = [0.30, 0.30, 0.33, 1.0];    // snap-fit tabs

// ============================================================
// HELPER MODULES
// ============================================================

module rbox(w, d, h, r) {
    hull()
        for (x=[r, w-r], y=[r, d-r])
            translate([x, y, 0]) cylinder(r=r, h=h);
}

// ============================================================
// COMPONENT MODULES
// ============================================================

// ── A. ENCLOSURE BODY ────────────────────────────────────────
module enclosure_body() {
    color(col_enc)
    difference() {
        rbox(enc_length, enc_width, enc_height - enc_lid, enc_fillet);
        translate([enc_wall, enc_wall, enc_floor])
            rbox(enc_length - 2*enc_wall,
                 enc_width  - 2*enc_wall,
                 enc_height,
                 max(enc_fillet - enc_wall, 1));
    }
    // Snap-fit tabs on long edges (visible in ref image)
    color(col_snap)
    for (y_off = [0, enc_width - 3])
        for (x_off = [enc_length * 0.25, enc_length * 0.75])
            translate([x_off - 4, y_off, enc_height * 0.6])
                cube([8, 3, 6]);
}

// ── A2. LID ──────────────────────────────────────────────────
module lid() {
    color(col_lid)
    translate([0, 0, enc_height - enc_lid])
        rbox(enc_length, enc_width, enc_lid, enc_fillet);
}

// ── B. RUBBER FEET (×4) ─────────────────────────────────────
module rubber_foot() {
    color(col_foot) {
        // mushroom cap
        cylinder(r=foot_r, h=foot_h_cap);
        // tapered neck
        translate([0, 0, foot_h_cap])
            cylinder(r1=foot_r*0.75, r2=foot_r_neck, h=foot_h_neck);
        // threaded base insert
        translate([0, 0, foot_h_cap + foot_h_neck])
            cylinder(r=foot_r_neck, h=foot_h_base);
    }
}

module feet() {
    total_foot_h = foot_h_cap + foot_h_neck + foot_h_base;
    for (x=[foot_inset_x, enc_length - foot_inset_x])
        for (y=[foot_inset_y, enc_width - foot_inset_y])
            translate([x, y, -total_foot_h])
                rubber_foot();
}

// ── C. BRASS STRUCTURAL BASE ─────────────────────────────────
module brass_base() {
    color(col_brass)
    translate([enc_wall + 2, enc_wall + 2, brass_z])
        cube([brass_w, brass_d, brass_h]);

    // Machined pockets for cable routing
    color(col_brass * 0.9)
    translate([enc_wall + brass_w * 0.6, enc_wall + 2, brass_z + brass_h - 3])
        cube([brass_w * 0.35, brass_d, 3]);
}

// ── D. VOICE COIL ACTUATOR ──────────────────────────────────
module voice_coil_actuator() {
    translate([vca_x, vca_y, vca_z]) {
        // Outer housing (steel cylinder)
        color(col_vca)
            cylinder(r=vca_od/2, h=vca_h);

        // Top magnet plate
        color(col_magnet)
            translate([0, 0, vca_h - vca_mag_h])
                cylinder(r=vca_od/2 + 0.5, h=vca_mag_h);

        // Inner copper coil winding (visible through gap)
        color(col_coil)
            translate([0, 0, (vca_h - vca_coil_h)/2])
                difference() {
                    cylinder(r=vca_coil_od/2, h=vca_coil_h);
                    cylinder(r=vca_coil_id/2, h=vca_coil_h);
                }

        // Centre pole piece (steel)
        color(col_magnet)
            cylinder(r=vca_coil_id/2 - 1, h=vca_h);
    }
}

// ── E. PLUNGER & LINEAR GUIDE ────────────────────────────────
module plunger_assembly() {
    translate([vca_x, vca_y, vca_z]) {
        // Brass plunger shaft (extends up through VCA)
        color(col_plunger)
            translate([0, 0, -2])
                cylinder(r=plunger_r, h=plunger_h + vca_h + 4);

        // PTFE guide block (purple/magenta in ref image)
        color(col_guide)
            translate([vca_od/2 + 2,
                       -plunger_guide_d/2,
                       vca_h * 0.3])
                cube([plunger_guide_w, plunger_guide_d, plunger_guide_h]);

        // Guide rail
        color(col_magnet)
            translate([vca_od/2 + 2 + plunger_guide_w,
                       -3, vca_h * 0.3 + 2])
                cube([6, 6, plunger_guide_h - 4]);
    }
}

// ── F. SPIRAL SPRING DISC (FLEXURE) ──────────────────────────
module spiral_spring_disc() {
    color(col_spring)
    translate([vca_x, vca_y, spring_disc_z]) {
        difference() {
            cylinder(r=spring_disc_r, h=spring_disc_h);
            // Concentric spiral grooves
            for (i = [1 : spring_n_rings])
                difference() {
                    cylinder(r = spring_disc_r * i / spring_n_rings,
                             h = spring_disc_h);
                    cylinder(r = spring_disc_r * i / spring_n_rings - spring_ring_w,
                             h = spring_disc_h);
                }
            // Centre hole for plunger
            cylinder(r=plunger_r + 1, h=spring_disc_h);
        }
    }
}

// ── G. COPPER CONTACT PLATE ─────────────────────────────────
module contact_plate() {
    translate([vca_x, vca_y, contact_z]) {
        // Main disc
        color(col_contact)
            cylinder(r=contact_r, h=contact_h);
        // Raised rim
        color(col_contact * 0.85)
            difference() {
                cylinder(r=contact_r, h=contact_h + contact_rim_h);
                cylinder(r=contact_r - 3, h=contact_h + contact_rim_h);
            }
        // Centre coupling nub
        color(col_plunger)
            cylinder(r=plunger_r - 1, h=contact_h + 4);
    }
}

// ── H. ADXL355 ACCELEROMETERS (×2, on carrier PCBs) ─────────
module adxl355_on_pcb(offset_x) {
    translate([vca_x + offset_x, vca_y, spring_disc_z + spring_disc_h]) {
        // Carrier PCB
        color(col_adxl)
            translate([-adxl_pcb_w/2, -adxl_pcb_d/2, 0])
                cube([adxl_pcb_w, adxl_pcb_d, adxl_pcb_h]);
        // ADXL355 IC (6×6×2.1 mm LCC-14)
        color(col_adxl_ic)
            translate([-adxl_w/2, -adxl_d/2, adxl_pcb_h])
                cube([adxl_w, adxl_d, adxl_h]);
        // Bond pads (14 LCC)
        color([0.80, 0.75, 0.20])
            for (side = [0, 1])
                for (i = [0 : 3])
                    translate([-adxl_w/2 + 1 + i*1.2,
                               side * (adxl_d - 0.6) - adxl_d/2,
                               adxl_pcb_h + adxl_h])
                        cube([0.8, 0.6, 0.3]);
    }
}

module adxl355_pickups() {
    adxl355_on_pcb(adxl1_offset_x);   // Pickup 1
    adxl355_on_pcb(adxl2_offset_x);   // Pickup 2

    // Baseline marker (red line, 40 mm conceptual)
    color([0.9, 0.1, 0.1, 0.7])
    translate([vca_x + adxl1_offset_x, vca_y - 0.5,
               spring_disc_z + spring_disc_h + adxl_pcb_h + adxl_h + 1])
        cube([adxl2_offset_x - adxl1_offset_x, 1, 1]);
}

// ── I. TAL221 LOAD CELL ─────────────────────────────────────
module tal221_load_cell() {
    translate([lc_x, lc_y, lc_z]) {
        // Aluminium beam body (47 × 12 × 6 mm)
        color(col_lc) {
            difference() {
                cube([lc_w, lc_d, lc_h]);
                // Strain gauge relief slot
                translate([lc_w * 0.3, 2, 1])
                    cube([lc_w * 0.4, lc_d - 4, lc_h - 2]);
                // M3 mounting holes
                translate([4.5, lc_d/2, 0]) cylinder(r=lc_hole_r, h=lc_h);
                translate([lc_w - 4.5, lc_d/2, 0]) cylinder(r=lc_hole_r, h=lc_h);
            }
        }
        // Strain gauge (bonded foil)
        color(col_strain)
            translate([lc_w * 0.35, 3, lc_h])
                cube([lc_w * 0.3, lc_d - 6, 0.5]);
        // 4-wire cable stub
        color(col_wire)
            translate([lc_w, lc_d/2 - 2, lc_h/2])
                rotate([0, 90, 0])
                    cylinder(r=1.5, h=8);
    }
}

// ── J. HX711 ADC BREAKOUT ────────────────────────────────────
module hx711_board() {
    translate([hx_x, hx_y, hx_z]) {
        // PCB (22 × 22 mm, green)
        color(col_hx) cube([hx_w, hx_d, 1.6]);
        // HX711 IC (SOIC-16)
        color(col_hx_ic)
            translate([6, 6, 1.6]) cube([10, 10, 2]);
        // Header pins
        color([0.75, 0.75, 0.20])
            for (i = [0 : 3])
                translate([2 + i*5, 1, -3]) cube([2, 2, 4.6]);
        // Capacitors / passives
        color([0.70, 0.60, 0.30])
            for (i = [0 : 2])
                translate([3 + i*7, hx_d - 4, 1.6]) cube([3, 2, 1.5]);
    }
}

// ── K. MLX90621 THERMAL ARRAY (TO-39) ────────────────────────
module mlx90621() {
    translate([mlx_x, mlx_y, mlx_z]) {
        // TO-39 metal can body
        color(col_mlx)
            difference() {
                cylinder(r=mlx_r, h=mlx_h);
                // Hollow interior
                translate([0, 0, 1])
                    cylinder(r=mlx_r - 0.8, h=mlx_h);
            }
        // Silicon lens window (top)
        color(col_mlx_lens)
            translate([0, 0, mlx_h])
                cylinder(r=mlx_lens, h=mlx_lens_h);
        // 4 leads (TO-39 pinout)
        color([0.75, 0.75, 0.20])
            for (a = [0 : 3])
                rotate([0, 0, a * 90 + 45])
                    translate([mlx_r * 0.5, 0, -4])
                        cylinder(r=0.5, h=5);
        // Orientation tab on can
        color(col_mlx)
            translate([mlx_r - 1, -1.5, 0]) cube([2, 3, mlx_h]);
    }
}

// ── L. ESP32-S3 DevKitC MODULES (×2) ────────────────────────
module esp32_module(x_pos, y_pos) {
    translate([x_pos, y_pos, esp_z]) {
        // PCB (62.74 × 25.40 mm, rotated 90° → 25.40 × 62.74)
        color(col_esp) cube([esp_d, esp_w, 1.6]);
        // ESP32-S3 metal shield
        color(col_esp_ic)
            translate([3, 10, 1.6])
                cube([esp_d - 6, 18, 3]);
        // USB-C connector stub
        color([0.65, 0.65, 0.68])
            translate([esp_d/2 - 4.5, -2, 1.6])
                cube([9, 7, 3.5]);
        // Antenna area (PCB exposed copper)
        color([0.80, 0.70, 0.15])
            translate([1, esp_w - 15, 1.6])
                cube([esp_d - 2, 14, 0.5]);
        // Pin headers (double row along both long edges)
        color([0.10, 0.10, 0.10])
            for (side = [0, 1])
                translate([side * (esp_d - 2.54), 5, -6])
                    cube([2.54, esp_w - 10, 7.6]);
        // Status LED
        color([0.1, 0.9, 0.1, 0.8])
            translate([esp_d/2, 5, 1.6])
                cylinder(r=1, h=1);
    }
}

module esp32_modules() {
    esp32_module(esp1_x, esp1_y);
    esp32_module(esp2_x, esp2_y);
}

// ── M. DIRECTION ARROWS (green, decorative) ─────────────────
module direction_arrows() {
    arrow_base_z = contact_z + contact_h + 2;
    translate([vca_x, vca_y, arrow_base_z]) {
        color(col_arrow) {
            // Vertical (Z) — main shear-wave excitation
            cylinder(r=2, h=16);
            translate([0, 0, 16]) cylinder(r1=5, r2=0, h=7);

            // Lateral oscillation indicators (curved arcs)
            for (angle = [-40, 40])
                rotate([0, angle, 0])
                    translate([0, 0, 10])
                        cylinder(r=1.2, h=12);

            // Down arrow (preload direction)
            translate([0, 0, -4]) cylinder(r1=0, r2=4, h=5);
        }
    }
}

// ── N. WIRING HARNESS (signal + power) ──────────────────────
module wiring() {
    color(col_wire) {
        // Load cell → HX711 (4-wire)
        hull() {
            translate([lc_x + lc_w, lc_y + lc_d/2, lc_z + lc_h/2]) sphere(r=0.8);
            translate([hx_x, hx_y + hx_d/2, hx_z + 2]) sphere(r=0.8);
        }
        // HX711 → ESP32 #1
        hull() {
            translate([hx_x + hx_w/2, hx_y + hx_d, hx_z + 2]) sphere(r=0.8);
            translate([esp1_x + esp_d/2, esp1_y + esp_w/2, esp_z + 2]) sphere(r=0.8);
        }
        // ADXL355 pickups → ESP32 #1 (SPI bus)
        for (ox = [adxl1_offset_x, adxl2_offset_x])
            hull() {
                translate([vca_x + ox, vca_y, spring_disc_z + spring_disc_h + 4]) sphere(r=0.6);
                translate([esp1_x + esp_d/2, esp1_y + 10, esp_z + 2]) sphere(r=0.6);
            }
        // MLX90621 → ESP32 #2 (I²C bus)
        hull() {
            translate([mlx_x, mlx_y, mlx_z + 2]) sphere(r=0.6);
            translate([esp2_x + esp_d/2, esp2_y + esp_w/2, esp_z + 2]) sphere(r=0.6);
        }
        // VCA drive → ESP32 #1 (DAC/PWM)
        hull() {
            translate([vca_x + vca_od/2, vca_y, vca_z + vca_h/2]) sphere(r=0.8);
            translate([esp1_x + esp_d, esp1_y + 20, esp_z + 2]) sphere(r=0.8);
        }
    }
}

// ── O. PCB STANDOFFS (M3 brass) ─────────────────────────────
module standoff(x, y, h) {
    color([0.75, 0.70, 0.20])
    translate([x, y, brass_z + brass_h])
        difference() {
            cylinder(r=3, h=h);
            cylinder(r=1.5, h=h);   // M3 threaded hole
        }
}

module standoffs() {
    // ESP32 mounting
    standoff(esp1_x + 2, esp1_y + 5, esp_z - brass_z - brass_h);
    standoff(esp1_x + esp_d - 2, esp1_y + esp_w - 5, esp_z - brass_z - brass_h);
    standoff(esp2_x + 2, esp2_y + 5, esp_z - brass_z - brass_h);
    standoff(esp2_x + esp_d - 2, esp2_y + esp_w - 5, esp_z - brass_z - brass_h);
    // HX711 mounting
    standoff(hx_x + 2, hx_y + 2, hx_z - brass_z - brass_h);
    standoff(hx_x + hx_w - 2, hx_y + hx_d - 2, hx_z - brass_z - brass_h);
}

// ============================================================
// FULL ASSEMBLY
// ============================================================
module assembly() {
    // Mechanical structure
    enclosure_body();
    lid();
    feet();

    // Internal structure
    brass_base();

    // Left bay — sensing assembly
    voice_coil_actuator();
    plunger_assembly();
    spiral_spring_disc();
    contact_plate();
    adxl355_pickups();
    tal221_load_cell();
    hx711_board();

    // Right bay — electronics + thermal
    mlx90621();
    esp32_modules();
    standoffs();

    // Decorative
    direction_arrows();
    wiring();
}

// ── RENDER ──────────────────────────────────────────────────
assembly();

// ============================================================
// COMPONENT DATASHEET REFERENCE
// ============================================================
// ADXL355    : Analog Devices, LCC-14, 6.0×6.0×2.1 mm
//              Noise density 25 µg/√Hz, ±2g/±4g/±8g
// TAL221     : SparkFun SEN-14727, 47×12×6 mm, 5 kg capacity
// MLX90621   : Melexis, TO-39, ⌀9.2×7 mm, 16×4 FIR array
// HX711      : Avia Semi, SOIC-16, breakout 22×22 mm, 24-bit
// ESP32-S3   : Espressif DevKitC-1, 62.74×25.40 mm, BLE 5.0
// VCA        : Miniature housed, ⌀20×25 mm, 10–300 Hz, 0.1 N
// TAL221 wire: Red=Exc+, Black=Exc-, Green=Sig+, White=Sig-
//
// EXPORT: Comment out assembly(), call individual modules,
//         F6 → render, F7 → export STL
// ============================================================

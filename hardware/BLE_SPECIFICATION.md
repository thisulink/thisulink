# THISULINK™ Plantar Probe — BLE Telemetry Contract

| | |
|---|---|
| **Document** | BLE-SPEC-001 |
| **Subsystem** | Plantar Shear-Wave Elastography Probe |
| **Protocol version** | v1.0 (authoritative) · v2.0 (planned, §7) |
| **Status** | v1.0 implemented, unit-tested, in production |
| **Reference implementation** | [`thisulink_app/lib/features/screening/measure/probe_packet.dart`](../thisulink_app/lib/features/screening/measure/probe_packet.dart) |
| **Conformance tests** | [`thisulink_app/test/probe_packet_test.dart`](../thisulink_app/test/probe_packet_test.dart) — 18 cases |

---

## 1. Scope

This document is the **normative wire contract** between the THISULINK plantar
probe firmware and every client that decodes its telemetry. Firmware and client
teams both build to this document; neither may change the frame unilaterally.

A frame that does not conform is **discarded, never interpreted**. There is no
partial-parse or best-effort path: a malformed frame in a clinical instrument
is an absent measurement, not an approximate one.

---

## 2. Protocol header — permanently standardised

| | |
|---|---|
| **Magic number** | `0x5448` — ASCII `"TH"` |
| **Byte order** | Little-endian, `0x48 0x54` on the wire |
| **Offset** | Bytes 0–1 |

> **Conflict resolution — closed.**
> An early draft specified `0xDA 0x7A` as the frame header. That value is
> **permanently deprecated** and must not appear in firmware, clients, test
> fixtures or documentation. `0x5448` is the sole valid header.
>
> This resolution matches the shipped decoder and its conformance tests. A
> device transmitting `0xDA 0x7A` will have every frame rejected as malformed,
> producing a probe that connects successfully and silently yields no readings
> — the most expensive possible failure mode to diagnose in the field.

---

## 3. GATT profile

| Attribute | UUID | Properties | Payload |
|---|---|---|---|
| **Service** | `0xFFE0` | — | THISULINK Telemetry Service |
| **Telemetry characteristic** | `0xFFE1` | Notify | 73 bytes, one frame per notification |
| **Control characteristic** | `0xFFE2` | Write | 4 bytes, command frame |

### 3.1 Advertising

| Field | Value |
|---|---|
| Local name prefix | `THISULINK-PROBE` |
| Service UUID in advertisement | `0xFFE0` |
| Connection interval | 15–30 ms |
| Preferred PHY | 2M PHY where supported, 1M fallback |

The client discovers devices by name prefix **and** advertised service UUID.
Name alone is insufficient — the prefix is user-visible and therefore
spoofable.

### 3.2 Control characteristic (`0xFFE2`)

4-byte commands, little-endian.

| Byte 0 | Command | Bytes 1–3 | Effect |
|---|---|---|---|
| `0x01` | `TARE` | reserved, zero | Zero the load cell at current rest state |
| `0x02` | `START` | `uint16` duration (s), 1 byte reserved | Begin sweep and telemetry notification |
| `0x03` | `STOP` | reserved, zero | Halt sweep, stop notifications |
| `0x04` | `SELFTEST` | reserved, zero | Run actuator and sensor self-check |

The probe acknowledges by changing the status flags in the next telemetry
frame. There is no separate acknowledgement characteristic — state is always
read from telemetry, so the client never holds a command state the device does
not agree with.

---

## 4. Frame layout — v1.0 (authoritative)

**Total length: exactly 73 bytes.** Any other length is discarded without
inspection.

All multi-byte fields are **little-endian**. All physical quantities are
transmitted as scaled integers; floating point never crosses the wire.

| Offset | Len | Field | Type | Units | Notes |
|---|---|---|---|---|---|
| 0–1 | 2 | Header | `uint16` | — | `0x5448` (`"TH"`) |
| 2–3 | 2 | Sequence | `uint16` | — | Rolling counter, wraps at 65535 |
| 4–7 | 4 | Timestamp | `uint32` | s | Unix epoch, UTC |
| 8–11 | 4 | Pickup 1 acceleration | `int32` | µg | Sensor at x₁ = 105 mm |
| 12–15 | 4 | Pickup 2 acceleration | `int32` | µg | Sensor at x₂ = 145 mm |
| 16–19 | 4 | Phase delay | `int32` | µrad | Δφ between pickups |
| 20–23 | 4 | Shear-wave speed | `uint32` | mm/s | Derived cₛ |
| 24–27 | 4 | Young's modulus | `uint32` | Pa | Derived E |
| 28–31 | 4 | Load cell force | `uint32` | mN | Live preload |
| 32–35 | 4 | Thermal asymmetry ΔT | `int32` | m°C | Contralateral difference |
| 36–39 | 4 | VCA drive frequency | `uint32` | mHz | Current sweep point |
| 40 | 1 | Contact status | `uint8` | — | See §4.1 |
| 41–43 | 3 | Reserved | — | — | Zero-filled alignment padding |
| 44–47 | 4 | Blood glucose | `uint32` | mg/dL ×10 | `0` = no CGM value present |
| 48–71 | 24 | Reserved | — | — | Zero-filled, reserved for v2.0 |
| 72 | 1 | CRC-8/MAXIM | `uint8` | — | Over bytes 0–71 inclusive |

### 4.1 Contact status enumeration

| Value | Meaning | Client behaviour |
|---|---|---|
| `0` | No contact | Sample rejected; prompt operator to place foot |
| `1` | Contact OK | Sample eligible for averaging |
| `2` | Force out of range | Sample rejected; show live force guidance |

A sample is averaged into a scan result **only** when contact status is `1`
**and** the load cell reading falls within the interlock window (§5).

### 4.2 Documented ambiguity

The originating specification table listed contact status as a `uint8`
occupying bytes 40–43. A `uint8` is one byte. The field is read at byte 40,
with 41–43 treated as alignment padding — which is what the table's own byte
budget requires, since glucose begins at byte 44. This interpretation is
implemented and covered by conformance tests.

---

## 5. Preload interlock

| Parameter | Value |
|---|---|
| Valid window | **1.40 N – 1.60 N** (1400–1600 mN) |
| Enforcement | Firmware sets contact status `2` outside the window |
| Client enforcement | Independently re-checks the transmitted force value |

The interlock is enforced **twice**, in firmware and again in the client. This
is deliberate. A shear-wave speed measured at the wrong preload is not noisy —
it is systematically wrong, because tissue stiffness is load-dependent. A
single point of failure in that check would produce confidently incorrect
clinical values.

---

## 6. Integrity

### 6.1 CRC-8/MAXIM

| Parameter | Value |
|---|---|
| Polynomial | `0x31` (reflected: `0x8C`) |
| Initial value | `0x00` |
| Reflect in / out | Yes / Yes |
| Final XOR | `0x00` |
| Coverage | Bytes 0–71 inclusive |
| Placement | Byte 72 |
| Conformance vector | `CRC("123456789") = 0xA1` |

Also known as Dallas/1-Wire CRC-8.

### 6.2 Client validation order

```
   frame received
        │
        ▼
   length == 73 ? ──── no ──► DISCARD
        │ yes
        ▼
   header == 0x5448 ? ── no ──► DISCARD
        │ yes
        ▼
   CRC(bytes 0..71) == byte 72 ? ── no ──► DISCARD
        │ yes
        ▼
   decode fields
        │
        ▼
   contact == OK && 1.40 N ≤ force ≤ 1.60 N ? ── no ──► REJECT SAMPLE
        │ yes                                            (count, do not average)
        ▼
   include in scan average
```

Validation is ordered cheapest-first, and every rejection is terminal. A
rejected sample is **counted** — the operator is shown accepted and rejected
counts, so a probe that is subtly misapplied is visible rather than silently
degrading the average.

---

## 7. Frame layout — v2.0 (planned, not implemented)

An extended frame has been proposed carrying the full frequency-sweep bin
array, protocol versioning, battery state and a frame trailer.

| Offset | Len | Field | Units |
|---|---|---|---|
| 0–1 | 2 | Header `0x5448` | — |
| 2 | 1 | Protocol version | — |
| 3–4 | 2 | Device status & interlock flags | bitfield |
| 5–6 | 2 | Preload force | mN |
| 7–14 | 8 | Thermal array summary & contralateral ΔT | m°C |
| 15–54 | 40 | Frequency sweep bins & phase delays | — |
| 55–62 | 8 | Derived cₛ and dynamic modulus G′ | mm/s, Pa |
| 63–66 | 4 | Battery level & ambient temperature | % , m°C |
| 67–70 | 4 | Payload sequence counter | — |
| 71 | 1 | CRC-8/MAXIM | — |
| 72 | 1 | Trailer `0x0A` | — |

### 7.1 Status: proposal only

**v2.0 is not implemented in firmware or in any client.** It is documented here
so the design is not lost, and so no one mistakes it for the live contract.

v2.0 is **not** a superset of v1.0 — it relocates nearly every field and moves
the CRC from byte 72 to byte 71. The two are mutually unintelligible despite
both being 73 bytes, and a v2.0 frame fed to a v1.0 decoder fails CRC and is
discarded. That is the correct outcome, but it means the migration is a
coordinated firmware-and-client release, not a rolling upgrade.

### 7.2 Migration requirements

Before v2.0 may be adopted:

1. Byte 2 must carry the protocol version in **both** versions, so a decoder
   can dispatch. v1.0 currently has no version field — this is the blocking
   defect in the proposal.
2. The client decoder must support both layouts simultaneously during rollout.
3. The 18 conformance tests must be duplicated for v2.0 fixtures.
4. Field devices must be inventoried; a mixed fleet without version dispatch
   produces silent total data loss on the older half.

**Recommendation:** adopt a version byte into v1.0 as a point release (v1.1)
using one of the reserved bytes 48–71 *before* any v2.0 work begins. That
change is backward compatible — existing decoders ignore reserved bytes — and
it is the only thing that makes a later migration safe.

---

## 8. Conformance checklist

A firmware build is conformant when:

- [ ] Every frame is exactly 73 bytes
- [ ] Bytes 0–1 are `0x48 0x54` on the wire
- [ ] All multi-byte fields are little-endian
- [ ] Byte 72 is CRC-8/MAXIM over bytes 0–71
- [ ] `CRC("123456789") == 0xA1` verified on-target
- [ ] Reserved bytes 41–43 and 48–71 are zero-filled
- [ ] Contact status is `2` whenever force is outside 1400–1600 mN
- [ ] Glucose field is `0` when no CGM value is present, never a sentinel
- [ ] Sequence counter increments per frame and wraps cleanly at 65535
- [ ] `TARE` / `START` / `STOP` / `SELFTEST` are honoured on `0xFFE2`

---

## 9. Verification status

| Item | Status |
|---|---|
| Decoder implementation | Complete |
| Unit tests — layout, CRC, classification, rejection paths | 18 passing |
| CRC conformance vector | Verified |
| Round-trip encode/decode | Verified |
| **Validation against production probe firmware** | **Outstanding** |

The decoder is byte-exact against this specification. It has not yet been
exercised against production hardware, and a specification is not firmware.
On-target validation of §8 is a prerequisite for clinical deployment.

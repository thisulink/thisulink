# THISULINK™ Retinal Screening — 20D Optical Adapter & Edge AI

| | |
|---|---|
| **Document** | RET-SPEC-001 |
| **Subsystem** | Non-mydriatic fundus capture and diabetic retinopathy grading |
| **Grading scale** | ICDR, grades 0–4 |
| **Status** | Pipeline implemented, model asset outstanding — see §8 |

---

## 1. Clinical purpose

Diabetic retinopathy is asymptomatic until it threatens sight, and it is
treatable when found early. Screening is therefore near-universally
recommended and near-universally under-delivered in rural settings: it requires
an ophthalmologist, a fundus camera, and usually pharmacological dilation.

This subsystem removes all three constraints from the *screening* step. It does
not replace an ophthalmologist — it decides, at the point of care, who needs
one.

---

## 2. Optical interface

| Parameter | Specification |
|---|---|
| Condensing lens | **+20 D** Volk indirect ophthalmoscopy lens |
| Mounting | Spring-clip smartphone adapter, camera-axis aligned |
| Static field of view | **46°** |
| Internal baffling | **60° knife-edge anti-glare baffles** |
| Illumination | Smartphone LED, diffused, continuous |
| Working distance | Fixed by adapter geometry |

### Optical principle

The +20 D lens forms a real, inverted aerial image of the retina between lens
and camera. The phone focuses on that aerial image rather than on the eye
itself — indirect ophthalmoscopy, mechanised so that the geometry is set by the
adapter instead of by the examiner's hand.

### Why the baffles matter

The dominant failure of naive phone-plus-lens fundus photography is the corneal
specular reflection: the illumination LED returns off the tear film directly
into the sensor, and the resulting flare sits over the posterior pole — exactly
the region being screened.

The 60° knife-edge baffles separate the illumination and imaging paths inside
the adapter so that the specular return falls outside the collection aperture.
This is what makes the capture reproducible by a health worker rather than a
skill acquired over months.

---

## 3. Operational protocol

| Property | Value |
|---|---|
| Dilation | **None** — no pharmacological mydriasis |
| Duration | Approximately **60 seconds** per patient |
| Discomfort | None; no contact with the eye |
| Operator skill | Health worker, trained in-session |
| Eyes captured | Both, recorded separately |

### Non-mydriatic rationale

Dilating drops require a prescriber, impose 20–30 minutes of waiting, blur the
patient's vision for hours, and carry a small angle-closure risk. In a village
screening camp that combination reduces to: most patients are not screened.

Non-mydriatic capture accepts a smaller field of view in exchange for a screen
that can actually be delivered. The trade is deliberate: the posterior pole
visible without dilation contains the lesions that determine referability.

### Capture sequence

```
   1. Patient seated, ambient light reduced
   2. Adapter clipped to device, lens aligned to camera axis
   3. Operator positions to working distance — on-screen guide
   4. Right eye  → quality gate → capture → on-device grading
   5. Left eye   → quality gate → capture → on-device grading
   6. Both records written locally, queued for sync
```

---

## 4. Image quality gate

Grading is attempted **only** on images that pass an automated gate. This runs
before inference, on-device, while the patient is still in the chair.

| Check | Rejects | Operator prompt |
|---|---|---|
| **Blur** | Motion or defocus below sharpness floor | "Hold steady and retake" |
| **Illumination** | Under- or over-exposed; specular flare over the pole | "Reduce room light and retake" |
| **Disc centring** | Optic disc absent or outside the expected region | "Re-centre and retake" |

### Why the gate precedes the model

A classifier given an unreadable image does not abstain — it returns a
confident grade derived from noise. In a screening context that is worse than
no result, because a false "grade 0" removes the patient from follow-up
entirely.

The gate converts an ungradable image into a **retake while the patient is
present**, which costs fifteen seconds, rather than a false reassurance that
costs a referral.

---

## 5. Edge inference pipeline

| Parameter | Specification |
|---|---|
| Architecture | **EfficientNet-B0** |
| Quantisation | **INT8** |
| Runtime | ONNX Runtime / TensorFlow Lite, on-device |
| Input | 224 × 224 × 3 |
| Output | 5-class ICDR grade + referability probability |

### Preprocessing

```
   captured frame
        │
        ▼
   retina circle detection  ──► crop to the illuminated disc,
        │                       discarding black surround
        ▼
   square pad              ──► preserve aspect ratio; no anisotropic
        │                       stretch of lesion morphology
        ▼
   resize 224×224 (cubic)
        │
        ▼
   ImageNet mean/std normalisation
        │
        ▼
   INT8 inference
```

Aspect ratio is preserved by padding rather than stretching. Microaneurysms and
haemorrhages are graded partly on size and shape; anisotropic scaling distorts
exactly the features the model was trained on.

### Output contract

| Output | Type | Meaning |
|---|---|---|
| `predicted_dr_grade` | 0–4 | ICDR severity |
| `referable_dr_prob` | 0.0–1.0 | P(referable disease) |
| `referable_dr_flag` | boolean | **Grade ≥ 2** |

| ICDR grade | Description |
|---|---|
| 0 | No apparent retinopathy |
| 1 | Mild non-proliferative |
| 2 | Moderate non-proliferative |
| 3 | Severe non-proliferative |
| 4 | Proliferative |

### Why on-device

| Constraint | Consequence |
|---|---|
| Rural connectivity | Screening must complete with no uplink |
| Result timing | Patient is told the outcome before leaving |
| Data minimisation | Fundus images need not transit a network to be graded |
| Cost | No per-inference cloud charge per patient screened |

A cloud fallback endpoint exists for devices where on-device inference is
unavailable; it is the exception path, not the design.

---

## 6. Clinical integration

Results are written to `retinal_records` and participate in triage:

| Triage contribution | Threshold |
|---|---|
| RED | P(referable) ≥ 0.50 **and** grade ≥ 3 |
| ORANGE | P(referable) ≥ 0.50 |
| YELLOW | grade ≥ 2 |

### Physician override

The Specialist Clinical Workstation presents the fundus image with the model's
grade and probability, and the reviewing physician may record
`doctor_confirmed_grade`.

**The confirmed grade always supersedes the prediction — including when it is
0.** A physician recording "no retinopathy" over a model's grade 3 must not
have that decision silently reverted by a null-coalescing bug that treats 0 as
absent. This behaviour is explicitly covered by the triage engine's test suite.

---

## 7. Data handling

| Aspect | Handling |
|---|---|
| Storage | `retinal_records.image_file`, server-side file storage |
| Formats | JPEG, PNG |
| Maximum size | 10 MB per image |
| Laterality | `eye_side`: `left` \| `right`, recorded per image |
| Access | Staff roles only; patients have no access to the collection |
| Retention | Longitudinal — prior fundus images inform progression |

Each eye is a separate record. Retinopathy is frequently asymmetric, and a
merged bilateral record cannot represent a grade 3 right eye alongside a grade
0 left.

---

## 8. Implementation status

| Component | Status |
|---|---|
| `retinal_records` collection, relations, access rules | **Live in production** |
| Triage integration — grade and referability thresholds | **Live and verified** |
| Physician review, zoom/pan, override and sign-off UI | Implemented |
| Doctor-grade-supersedes-prediction logic | Implemented, unit-tested |
| Preprocessing chain and inference wiring | Implemented |
| **Trained INT8 model asset** | **Not bundled** |
| **Image quality gate** | **Not implemented** |
| **Optical adapter hardware** | **Not validated** |

Every surrounding path — capture, storage, review, override, triage — is live
and exercised with seeded grades. The model file
`thisulink_retinal_efficientnet_b0_int8.onnx` is not present in the bundle, so
on-device grading falls back to the configured server endpoint until it is
supplied.

**The quality gate is the gap that matters most.** Without it, the first
ungradable image produces a confident false grade, and §4 explains why that is
the one failure this subsystem must not have. It should be delivered with the
model asset, not after it.

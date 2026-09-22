const express = require('express');
const router  = express.Router();

// ── Triage logic (mirrors PocketBase hook triage.pb.js exactly) ───────────────
function computeTriageColour({ tissueClass, deltaT, drGrade, referableProb, glucose }) {
  const tc = tissueClass || 'A';
  const dT = parseFloat(deltaT)       || 0;
  const dg = parseInt(drGrade)        ?? -1;
  const rp = parseFloat(referableProb)|| 0;
  const gl = parseFloat(glucose)      || 0;

  if (tc === 'C' || (rp >= 0.50 && dg >= 3) || gl > 400) return 'Red';
  if ((tc === 'B' && dT >= 2.2) || rp >= 0.50 || gl > 300)  return 'Orange';
  if (tc === 'B' || dT >= 2.2 || dg >= 2 || gl > 180)       return 'Yellow';
  return 'Green';
}

function triageEmoji(colour) {
  return { Green: '🟢', Yellow: '🟡', Orange: '🟠', Red: '🔴' }[colour] || '⚪';
}

function triageAction(colour) {
  return {
    Green:  'No action needed — repeat full cycle in 6 days.',
    Yellow: 'Monitor — repeat scan in 3 days. ASHA worker to follow up.',
    Orange: 'ASHA worker alert — telemedicine review within 48 hours.',
    Red:    'Immediate specialist referral — do not wait.',
  }[colour];
}

// ── POST /api/triage/compute ──────────────────────────────────────────────────
// Body: { tissueClass, deltaT, drGrade, referableProb, glucose, patientId? }
router.post('/compute', (req, res) => {
  const { tissueClass, deltaT, drGrade, referableProb, glucose, patientId } = req.body;

  if (!tissueClass) {
    return res.status(400).json({ error: 'tissueClass is required (A, B, or C)' });
  }

  const colour = computeTriageColour({ tissueClass, deltaT, drGrade, referableProb, glucose });

  res.json({
    patient_id:    patientId || null,
    triage_colour: colour,
    emoji:         triageEmoji(colour),
    action:        triageAction(colour),
    inputs: {
      tissue_class:    tissueClass,
      delta_t_celsius: deltaT,
      dr_grade:        drGrade,
      referable_prob:  referableProb,
      glucose_mgdl:    glucose,
    },
    computed_at: new Date().toISOString(),
  });
});

// ── POST /api/triage/batch ────────────────────────────────────────────────────
// Body: { sessions: [{ patientId, tissueClass, deltaT, drGrade, referableProb, glucose }] }
router.post('/batch', (req, res) => {
  const { sessions } = req.body;

  if (!Array.isArray(sessions) || sessions.length === 0) {
    return res.status(400).json({ error: 'sessions array is required' });
  }

  const results = sessions.map((s) => {
    const colour = computeTriageColour(s);
    return {
      patient_id:    s.patientId || null,
      triage_colour: colour,
      emoji:         triageEmoji(colour),
      action:        triageAction(colour),
    };
  });

  const summary = {
    Green:  results.filter(r => r.triage_colour === 'Green').length,
    Yellow: results.filter(r => r.triage_colour === 'Yellow').length,
    Orange: results.filter(r => r.triage_colour === 'Orange').length,
    Red:    results.filter(r => r.triage_colour === 'Red').length,
  };

  res.json({ total: sessions.length, summary, results, computed_at: new Date().toISOString() });
});

// ── GET /api/triage/thresholds ────────────────────────────────────────────────
router.get('/thresholds', (req, res) => {
  res.json({
    tissue_class: {
      A: { label: 'Healthy',            E_kpa: '≤ 50',     cs_ms: '3.2 – 4.2' },
      B: { label: 'Early Glycation',    E_kpa: '51 – 150', cs_ms: '4.2 – 6.5' },
      C: { label: 'Diabetic Neuropathy',E_kpa: '> 150',    cs_ms: '> 6.5'      },
    },
    thermometry: {
      flag_threshold_celsius: 2.2,
      source: 'Armstrong & Lavery, Diabetes Care 1997',
    },
    glucose: {
      normal_mgdl:  '≤ 180',
      yellow_mgdl:  '181 – 300',
      orange_mgdl:  '301 – 400',
      red_mgdl:     '> 400',
    },
    retinal: {
      referable_threshold: 0.50,
      note: 'Sensitivity-first threshold not yet tuned on calibration split',
    },
    triage_logic: {
      Red:    'tissueClass==C OR (referable≥0.50 AND drGrade≥3) OR glucose>400',
      Orange: '(tissueClass==B AND ΔT≥2.2) OR referable≥0.50 OR glucose>300',
      Yellow: 'tissueClass==B OR ΔT≥2.2 OR drGrade≥2 OR glucose>180',
      Green:  'none of the above',
    },
  });
});

module.exports = router;

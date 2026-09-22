// Runs after every cycle_sessions record is created or updated.
// Computes the 4-tier triage colour and:
//   1. Writes a triage_results record
//   2. Updates patients.triage_colour
//   3. Creates a relay_alerts record for Orange / Red cases

// ── Helper: compute triage colour ────────────────────────────────────────────
function computeTriageColour(tissueClass, deltaT, drGrade, referableProb, glucose) {
  const tc = tissueClass  || 'A';
  const dT = parseFloat(deltaT)        || 0;
  const dg = parseInt(drGrade)         ?? -1;
  const rp = parseFloat(referableProb) || 0;
  const gl = parseFloat(glucose)       || 0;

  if (tc === 'C' || (rp >= 0.50 && dg >= 3) || gl > 400) return 'Red';
  if ((tc === 'B' && dT >= 2.2) || rp >= 0.50 || gl > 300)  return 'Orange';
  if (tc === 'B' || dT >= 2.2 || dg >= 2 || gl > 180)       return 'Yellow';
  return 'Green';
}

// ── Hook: on cycle_sessions CREATE ───────────────────────────────────────────
onRecordAfterCreateRequest((e) => {
  runTriage(e.record);
}, 'cycle_sessions');

// ── Hook: on cycle_sessions UPDATE ───────────────────────────────────────────
onRecordAfterUpdateRequest((e) => {
  runTriage(e.record);
}, 'cycle_sessions');

// ── Main triage runner ────────────────────────────────────────────────────────
function runTriage(session) {
  const colour = computeTriageColour(
    session.get('tissue_class'),
    session.get('delta_t_celsius'),
    session.get('dr_grade'),
    session.get('referable_prob'),
    session.get('glucose_mgdl'),
  );

  // 1. Write triage_results record
  const triageCol = $app.dao().findCollectionByNameOrId('triage_results');
  const triageRec = new Record(triageCol);
  triageRec.set('patient',       session.get('patient'));
  triageRec.set('session',       session.id);
  triageRec.set('triage_colour', colour);
  triageRec.set('computed_at',   new Date().toISOString());
  $app.dao().saveRecord(triageRec);

  // 2. Update patient's live triage_colour field
  const patient = $app.dao().findRecordById('patients', session.get('patient'));
  patient.set('triage_colour', colour);
  $app.dao().saveRecord(patient);

  // 3. Orange or Red → create relay alert for the ASHA worker
  if (colour === 'Orange' || colour === 'Red') {
    const patientName = patient.get('name');
    const cycleDay    = session.get('cycle_day');
    const ashaId      = patient.get('asha_worker');

    if (ashaId) {
      const alertCol = $app.dao().findCollectionByNameOrId('relay_alerts');
      const alert    = new Record(alertCol);
      alert.set('asha_worker',  ashaId);
      alert.set('patient',      patient.id);
      alert.set('message',
        `⚠️ ${patientName} — Triage ${colour} on Day ${cycleDay}. ` +
        (colour === 'Red'
          ? 'Immediate specialist referral required.'
          : 'Telemedicine review within 48 hours.')
      );
      alert.set('acknowledged', false);
      $app.dao().saveRecord(alert);
    }
  }
}

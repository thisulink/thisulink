const express = require('express');
const multer  = require('multer');
const sharp   = require('sharp');
const ort     = require('onnxruntime-node');
const path    = require('path');

const router = express.Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits:  { fileSize: 10 * 1024 * 1024 }, // 10 MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// ── ImageNet normalisation constants ─────────────────────────────────────────
const MEAN = [0.485, 0.456, 0.406];
const STD  = [0.229, 0.224, 0.225];
const INPUT_SIZE = 224;

// ── ONNX session (loaded once at startup) ────────────────────────────────────
const MODEL_PATH = process.env.ONNX_MODEL_PATH ||
  path.join(__dirname, '../../models/thisulink_retinal_efficientnet_b0_int8.onnx');

let session = null;
(async () => {
  try {
    session = await ort.InferenceSession.create(MODEL_PATH, {
      executionProviders: ['cpu'],
      graphOptimizationLevel: 'all',
    });
    console.log('✅  ONNX retinal model loaded:', MODEL_PATH);
  } catch (err) {
    console.error('❌  ONNX load failed:', err.message);
  }
})();

// ── Preprocessing ─────────────────────────────────────────────────────────────
async function preprocessImage(buffer) {
  // Step 1: detect retina circle (pixels > 12/255) and crop
  const raw = await sharp(buffer).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { data, info } = raw;

  let minX = info.width, minY = info.height, maxX = 0, maxY = 0;
  for (let y = 0; y < info.height; y++) {
    for (let x = 0; x < info.width; x++) {
      const idx = (y * info.width + x) * 4;
      const brightness = (data[idx] + data[idx + 1] + data[idx + 2]) / 3;
      if (brightness > 12) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  const cropW = Math.max(maxX - minX, 1);
  const cropH = Math.max(maxY - minY, 1);
  const squareSide = Math.max(cropW, cropH);

  // Step 2: crop → square pad → resize to 224×224
  const { data: resized } = await sharp(buffer)
    .extract({ left: minX, top: minY, width: cropW, height: cropH })
    .resize(squareSide, squareSide, { fit: 'contain', background: { r: 0, g: 0, b: 0 } })
    .resize(INPUT_SIZE, INPUT_SIZE, { kernel: sharp.kernel.lanczos3 })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  // Step 3: HWC → CHW + ImageNet normalise
  const float32 = new Float32Array(3 * INPUT_SIZE * INPUT_SIZE);
  for (let i = 0; i < INPUT_SIZE * INPUT_SIZE; i++) {
    float32[i]                            = (resized.data[i * 3]     / 255 - MEAN[0]) / STD[0];
    float32[i + INPUT_SIZE * INPUT_SIZE]  = (resized.data[i * 3 + 1] / 255 - MEAN[1]) / STD[1];
    float32[i + 2 * INPUT_SIZE * INPUT_SIZE] = (resized.data[i * 3 + 2] / 255 - MEAN[2]) / STD[2];
  }

  return new ort.Tensor('float32', float32, [1, 3, INPUT_SIZE, INPUT_SIZE]);
}

// ── Triage contribution from retinal alone ────────────────────────────────────
function retinalTriageContribution(drGrade, referableProb) {
  if (referableProb >= 0.50 && drGrade >= 3) return 'RED';
  if (referableProb >= 0.50)                  return 'ORANGE';
  if (drGrade >= 2)                            return 'YELLOW';
  return 'GREEN';
}

// ── POST /api/retinal/grade ───────────────────────────────────────────────────
// multipart/form-data  field: image (JPEG / PNG)
// Optional query:      ?patient_id=...&cycle_day=...
router.post('/grade', upload.single('image'), async (req, res, next) => {
  try {
    if (!session) {
      return res.status(503).json({ error: 'ONNX model not ready — check server logs' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'No image provided (field name: image)' });
    }

    const inputTensor = await preprocessImage(req.file.buffer);
    const results     = await session.run({ input: inputTensor });

    const gradeProbs    = Array.from(results['grade_probs'].data);
    const referableRaw  = results['referable_prob'].data[0];
    const predictedGrade = gradeProbs.indexOf(Math.max(...gradeProbs));

    const GRADE_NAMES = ['No DR', 'Mild NPDR', 'Moderate NPDR', 'Severe NPDR', 'Proliferative DR'];

    res.json({
      thisulink_module:  'retinal',
      patient_id:        req.query.patient_id  || null,
      cycle_day:         req.query.cycle_day   || null,
      research_output: {
        predicted_dr_grade:      predictedGrade,
        grade_name:              GRADE_NAMES[predictedGrade],
        grade_probabilities: {
          '0': +gradeProbs[0].toFixed(4),
          '1': +gradeProbs[1].toFixed(4),
          '2': +gradeProbs[2].toFixed(4),
          '3': +gradeProbs[3].toFixed(4),
          '4': +gradeProbs[4].toFixed(4),
        },
        referable_dr_probability: +referableRaw.toFixed(4),
        referable:                referableRaw >= 0.50,
        triage_contribution:      retinalTriageContribution(predictedGrade, referableRaw),
      },
      preprocessing: {
        original_size:  [req.file.size, 'bytes'],
        model_input:    [INPUT_SIZE, INPUT_SIZE],
      },
      disclaimer: 'Research output only — not a diagnosis. A qualified clinician must review all outputs before any clinical decision.',
    });
  } catch (err) {
    next(err);
  }
});

// ── GET /api/retinal/model-info ───────────────────────────────────────────────
router.get('/model-info', (req, res) => {
  res.json({
    model:      'EfficientNet-B0 INT8 ONNX',
    dataset:    'APTOS 2019 (3,385 images after deduplication)',
    input:      '1 × 3 × 224 × 224 float32, ImageNet normalised',
    outputs:    { grade_probs: '[1,5] softmax', referable_prob: '[1,1] sigmoid' },
    metrics: {
      qwk:      0.860,
      auc:      0.976,
      ece:      0.046,
      test_n:   677,
    },
    model_path: MODEL_PATH,
    loaded:     session !== null,
  });
});

module.exports = router;

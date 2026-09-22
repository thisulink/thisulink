const express = require('express');
const router  = express.Router();

// GET /api/health
router.get('/', (req, res) => {
  res.json({
    status:    'ok',
    service:   'thisulink-api',
    version:   require('../../package.json').version,
    timestamp: new Date().toISOString(),
    uptime_s:  Math.floor(process.uptime()),
    env:       process.env.NODE_ENV,
    pb_url:    process.env.PB_URL,
  });
});

module.exports = router;

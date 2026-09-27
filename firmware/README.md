# THISULINK™ — Embedded Firmware Architecture

This directory houses the embedded firmware implementations powering the THISULINK point-of-care biomechanical diagnostic hardware.

---

## 1. Directory Structure

```
firmware/
└── thisulink-esp32s3-adxl345/
    └── arduino/
        └── thisulink_firmware/
            ├── thisulink_firmware.ino       # Main application loop & command router
            ├── ADXL345_Driver.h/.cpp        # SPI/I²C low-noise hardware driver
            ├── AcquisitionEngine.h/.cpp     # High-speed ring buffer & interrupt sampling
            ├── DSPFilters.h/.cpp            # Real-time biquad IIR filters & detrending
            ├── FFTEngine.h/.cpp             # 2048-pt Radix-2 Cooley-Tukey FFT & peak picker
            ├── FeatureExtractor.h/.cpp      # Time/frequency mechanical feature vector
            ├── SensorCalibration.h/.cpp     # Static gravity bias calibration
            ├── PositionManager.h/.cpp       # Multi-site anatomical scan manager
            ├── DataLogger.h/.cpp            # High-throughput serial/BLE telemetry logger
            ├── SerialConsole.h/.cpp         # Interactive ASCII diagnostics shell
            └── README.md                    # Detailed firmware DSP & architecture manual
```

---

## 2. Firmware Roles & Evolution

| Firmware Package | Platform / Target | Accelerometer | Status | Purpose |
|---|---|---|---|---|
| **`thisulink_firmware`** | ESP32-S3 DevKitC-1 | ADXL345 (13-bit) | Validated POC | Validates the on-device DSP pipeline, real-time FFT, and mechanical feature extraction before clinical production. |
| **`production_probe`** | ESP32-S3 Custom SoC | Dual ADXL355 (20-bit) | Production Contract | Dual-pickup synchronized sampling across the fixed $\Delta x = 40.0\text{ mm}$ baseline conforming to [hardware/BLE_SPECIFICATION.md](../hardware/BLE_SPECIFICATION.md). |

---

## 3. Quick Links

- [Hardware Specification](../hardware/README.md)
- [BLE Wire Contract Specification](../hardware/BLE_SPECIFICATION.md)
- [Mechanical Research Firmware Detailed Guide](thisulink-esp32s3-adxl345/arduino/thisulink_firmware/README.md)

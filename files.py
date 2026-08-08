from pathlib import Path

repo = Path("DIA-TISSUE-MATLAB-SIMULATION")

folders = [
    "common",
    "01_Baseline_Mechanical_Response/results",
    "02_Stiffness_Comparison/results",
    "03_Frequency_Sweep/results",
    "04_FFT_Analysis/results",
    "05_Sensor_Simulation/results",
    "06_Noise_SNR_Analysis/results",
    "07_Contact_Force_Sensitivity/results",
    "08_Load_Cell_Validation/results",
    "09_VCA_Electrical_Test/results",
]

for folder in folders:
    path = repo / folder
    path.mkdir(parents=True, exist_ok=True)
    print(f"Created: {path}")

print("\n========================================")
print("DIA-TISSUE repository structure created")
print("========================================")
print(f"Location: {repo.resolve()}")
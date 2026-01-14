# SDTM/ADaM/BDM Automation Framework - Quick Start Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Navigate to Project Directory
```r
setwd("d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas")
```

### Step 2: Install Packages (First Time Only)
```r
source("R/setup/00_install_packages.R")
```
⏱️ **Time**: 10-15 minutes (one-time setup)

### Step 3: Run Complete Automation
```r
source("R/run_all.R")
```
⏱️ **Time**: 5-10 minutes (depending on data size)

**That's it!** Your SDTM, ADaM, and BDM files will be generated automatically.

---

## 📁 What Gets Generated

### SDTM Datasets (10 domains)
📂 Location: `data/sdtm/`
- ✅ DM (Demographics)
- ✅ AE (Adverse Events)  
- ✅ VS (Vital Signs)
- ✅ LB (Laboratory)
- ✅ CM (Concomitant Medications)
- ✅ EG (ECG)
- ✅ EX (Exposure)
- ✅ DS (Disposition)
- ✅ MH (Medical History)
- ✅ SU (Substance Use)

**Formats**: XPT, SAS7BDAT, CSV

### ADaM Datasets (6 datasets)
📂 Location: `data/adam/`
- ✅ ADSL (Subject-Level Analysis)
- ✅ ADAE (AE Analysis)
- ✅ ADLB (Laboratory Analysis)
- ✅ ADVS (Vital Signs Analysis)
- ✅ ADEG (ECG Analysis)
- ✅ ADCM (Concomitant Medications Analysis)

**Formats**: XPT, SAS7BDAT, CSV

### BDM Specifications (11 files)
📂 Location: `specs/bdm/`
- ✅ BDM for each domain (Excel format)
- ✅ Master BDM Index

---

## 🎯 Common Tasks

### Generate Only SDTM Domains
```r
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

# Generate specific domains
source("R/sdtm/sdtm_dm.R")
source("R/sdtm/sdtm_ae.R")
source("R/sdtm/sdtm_vs.R")
# ... etc
```

### Generate Only ADaM Datasets
```r
# Prerequisites: SDTM domains must exist first
source("R/adam/adam_adsl.R")  # Must run first
source("R/adam/adam_adae.R")
source("R/adam/adam_adlb.R")
# ... etc
```

### Generate Only BDM Specifications
```r
source("R/bdm/generate_all_bdm.R")
```

### Validate BDM Specifications
```r
source("R/bdm/validate_bdm.R")
```

---

## ⚙️ Configuration

### Customize Study Information
Edit `R/setup/01_config.R`:

```r
STUDY_CONFIG <- list(
  study_id = "YOUR_STUDY_ID",
  protocol = "YOUR_PROTOCOL",
  sponsor = "Your Company Name",
  # ... etc
)
```

### Customize Export Formats
Edit `R/setup/01_config.R`:

```r
EXPORT_CONFIG <- list(
  export_sas = TRUE,   # Export SAS7BDAT?
  export_csv = TRUE,   # Export CSV?
  xpt_version = "5"    # XPT version
)
```

---

## 📊 Output Structure

```
CDB/sas/
├── data/
│   ├── sdtm/
│   │   ├── dm.xpt, dm.sas7bdat, dm.csv
│   │   ├── ae.xpt, ae.sas7bdat, ae.csv
│   │   └── ... (all domains)
│   └── adam/
│       ├── adsl.xpt, adsl.sas7bdat, adsl.csv
│       ├── adae.xpt, adae.sas7bdat, adae.csv
│       └── ... (all datasets)
├── specs/bdm/
│   ├── BDM_DM_Demographics.xlsx
│   ├── BDM_AE_Adverse_Events.xlsx
│   ├── ... (all BDM files)
│   └── BDM_Master_Index.xlsx
└── outputs/
    ├── logs/
    │   └── [timestamp]_logs.log
    └── reports/
        └── execution_summary_[timestamp].txt
```

---

## 🔍 Verification

### Check Execution Summary
```r
# View latest execution summary
summary_files <- list.files("outputs/reports", pattern = "execution_summary", full.names = TRUE)
latest_summary <- summary_files[length(summary_files)]
file.show(latest_summary)
```

### Check Generated Files
```r
# List SDTM datasets
list.files("data/sdtm")

# List ADaM datasets
list.files("data/adam")

# List BDM specifications
list.files("specs/bdm")
```

### View Logs
```r
# View latest log
log_files <- list.files("outputs/logs", pattern = "\\.log$", full.names = TRUE)
latest_log <- log_files[length(log_files)]
file.show(latest_log)
```

---

## 🛠️ Troubleshooting

### Issue: Packages Won't Install
```r
# Install manually
install.packages(c("admiral", "haven", "dplyr", "tidyr", "purrr", 
                   "lubridate", "stringr", "glue", "xportr"))
```

### Issue: Can't Read SAS Files
```r
# Check file exists
file.exists("sas/dmgen.sas7bdat")

# Try reading manually
library(haven)
dm <- read_sas("sas/dmgen.sas7bdat")
View(dm)
```

### Issue: Script Fails Mid-Execution
```r
# Check the log file for errors
log_files <- list.files("outputs/logs", full.names = TRUE)
latest_log <- log_files[length(log_files)]
readLines(latest_log, n = 100)  # Read last 100 lines
```

### Issue: Missing Output Files
```r
# Verify directories exist
dir.exists("data/sdtm")
dir.exists("data/adam")
dir.exists("specs/bdm")

# Re-run specific domain
source("R/sdtm/sdtm_dm.R")
```

---

## 📚 Next Steps

1. **Review Generated Datasets**
   - Open XPT files in SAS
   - Open CSV files in Excel/R
   - Verify record counts and variable names

2. **Review BDM Specifications**
   - Open Excel files in `specs/bdm/`
   - Verify mappings are correct
   - Add any missing derivation logic

3. **Run Validation**
   ```r
   source("R/bdm/validate_bdm.R")
   ```

4. **Customize for Your Study**
   - Update configuration in `R/setup/01_config.R`
   - Add study-specific derivations
   - Modify controlled terminology mappings

5. **Add More Domains** (if needed)
   - Use existing scripts as templates
   - Follow the same structure
   - Add to `run_all.R`

---

## 💡 Tips

- **Run incrementally**: Test one domain at a time before running all
- **Check logs**: Always review logs after execution
- **Backup data**: Keep original SAS files unchanged
- **Version control**: Use Git to track changes to scripts
- **Document changes**: Update BDM specs when modifying code

---

## 📞 Support

For detailed documentation, see:
- `README.md` - Main framework documentation
- `R/bdm/README.md` - BDM generation documentation
- `walkthrough.md` - Complete walkthrough of all scripts

---

**Framework Version**: 1.0.0  
**Last Updated**: 2025-12-28

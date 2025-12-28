# Pinnacle 21 Validation - Quick Start Guide

## Overview

The Pinnacle 21 (P21) validation framework provides automated CDISC compliance checking for SDTM and ADaM datasets using Pinnacle 21 Community.

## Prerequisites

### 1. Install Pinnacle 21 Community

Download and install from: https://www.pinnacle21.com/products/pinnacle-21-community

**Default Installation Path (Windows)**:
```
C:\Program Files\Pinnacle 21 Community\
```

### 2. Update Configuration

If P21 is installed in a different location, update the path in `R/validation/run_p21_validation.R`:

```r
# Line 15
P21_PATH <- "C:/Your/Custom/Path/Pinnacle 21 Community/bin/p21c.exe"
```

## Usage

### Option 1: Run P21 Validation Only

```r
source("R/validation/run_p21_validation.R")
```

### Option 2: Run All Validation (Includes P21)

Uncomment P21 section in `R/validation/run_all_validation.R` (lines 44-49), then:

```r
source("R/validation/run_all_validation.R")
```

### Option 3: Command Line (Direct P21)

```powershell
# SDTM Validation
"C:\Program Files\Pinnacle 21 Community\bin\p21c.exe" validate `
  --type=sdtm `
  --version=3.2 `
  --ct-version=2023-12-15 `
  --input="d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/data/sdtm" `
  --output="d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/outputs/validation/p21_reports/sdtm" `
  --format=xlsx

# ADaM Validation
"C:\Program Files\Pinnacle 21 Community\bin\p21c.exe" validate `
  --type=adam `
  --version=1.1 `
  --ct-version=2023-12-15 `
  --input="d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/data/adam" `
  --output="d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/outputs/validation/p21_reports/adam" `
  --format=xlsx
```

## What P21 Validates

### SDTM Validation
- ✅ Required variables presence
- ✅ Variable naming conventions
- ✅ Variable data types
- ✅ Variable lengths
- ✅ Controlled terminology compliance
- ✅ ISO 8601 date formats
- ✅ Domain-specific rules
- ✅ Relationships between domains
- ✅ SDTM Implementation Guide conformance

### ADaM Validation
- ✅ Required variables (STUDYID, USUBJID, etc.)
- ✅ Variable naming conventions
- ✅ Analysis flags (SAFFL, ITTFL, etc.)
- ✅ Traceability to SDTM
- ✅ ADaM structure (BDS, ADSL, OCCDS)
- ✅ Analysis value derivations
- ✅ ADaM Implementation Guide conformance

## Output Reports

### Report Location
```
outputs/validation/p21_reports/
├── sdtm/
│   └── P21_SDTM_Report.xlsx
├── adam/
│   └── P21_ADaM_Report.xlsx
└── P21_Validation_Summary.md
```

### Excel Report Sheets

1. **Issues**: Detailed list of all validation findings
   - Rule ID
   - Severity (Error, Warning, Note)
   - Dataset
   - Variable
   - Message
   - Record count

2. **Summary**: High-level statistics
   - Total datasets validated
   - Total issues by severity
   - Pass/fail status

3. **Datasets**: List of validated datasets
   - Dataset name
   - Record count
   - Variable count

## Issue Severity Levels

| Severity | Description | Action Required |
|----------|-------------|-----------------|
| **Error** | CDISC compliance violation | **Must fix** before submission |
| **Warning** | Potential issue or best practice | Review and document if accepted |
| **Note** | Informational message | Review for awareness |

## Typical Workflow

### 1. Generate Datasets
```r
source("R/run_all.R")  # Generate SDTM + ADaM
```

### 2. Run P21 Validation
```r
source("R/validation/run_p21_validation.R")
```

### 3. Review Reports
- Open Excel reports in `outputs/validation/p21_reports/`
- Sort by Severity (Error → Warning → Note)
- Review each issue

### 4. Fix Issues
- Update source data or derivation scripts
- Re-run affected domain scripts
- Re-validate

### 5. Document Accepted Deviations
- For any Warning-level issues you accept
- Document rationale in validation report
- Include in submission documentation

## Common P21 Issues and Fixes

### Issue: Missing Required Variable
```
Error: Variable USUBJID not found in dataset DM
```
**Fix**: Add USUBJID derivation in `R/sdtm/sdtm_dm.R`

### Issue: Invalid Controlled Terminology
```
Warning: Value 'MALE' for variable SEX is not in CDISC CT
```
**Fix**: Use 'M' instead of 'MALE' (apply CT mapping)

### Issue: Non-ISO 8601 Date Format
```
Error: Variable RFSTDTC contains non-ISO 8601 date: '01JAN2023'
```
**Fix**: Convert to '2023-01-01' format

### Issue: Variable Name Too Long
```
Error: Variable TREATMENTGROUP exceeds 8 characters (SDTM limit)
```
**Fix**: Rename to 'TRTGRP' or similar (≤8 chars)

### Issue: Invalid Variable Type
```
Error: Variable AGE should be numeric but is character
```
**Fix**: Convert to numeric in derivation script

## Integration with Framework

The P21 validation is integrated into the complete validation workflow:

```
1. CDISC Compliance Checks (R-based)
   ↓
2. Statistical QC Checks (R-based)
   ↓
3. Pinnacle 21 Validation (P21 Community)
   ↓
4. Master Validation Report
```

## Troubleshooting

### P21 Not Found
```
WARNING: Pinnacle 21 Community not found at: C:/Program Files/Pinnacle 21 Community/bin/p21c.exe
```
**Solution**: 
1. Install P21 Community
2. Update `P21_PATH` in script
3. Verify path exists

### No XPT Files Found
```
No SDTM XPT files found. Please generate SDTM datasets first.
```
**Solution**: Run `source("R/run_all.R")` first

### P21 Command Failed
```
Error running P21 validation: ...
```
**Solution**:
1. Check P21 is properly installed
2. Verify input/output paths exist
3. Check XPT files are valid SAS Transport v5
4. Run P21 manually to see detailed error

## Advanced Options

### Custom CDISC CT Version
Update in `R/setup/01_config.R`:
```r
STUDY_CONFIG <- list(
  cdisc_ct_version = "2024-06-28"  # Use latest CT version
)
```

### Validate Specific Domains Only
Modify script to validate only selected datasets:
```r
# Copy specific XPT files to temp directory
# Run P21 on temp directory
```

### Generate Define.xml
P21 can also generate Define.xml (separate feature):
```powershell
"C:\Program Files\Pinnacle 21 Community\bin\p21c.exe" define `
  --type=sdtm `
  --input="path/to/sdtm" `
  --output="path/to/define.xml"
```

## Resources

- **P21 Community Documentation**: https://www.pinnacle21.com/documentation
- **CDISC SDTM IG**: https://www.cdisc.org/standards/foundational/sdtm
- **CDISC ADaM IG**: https://www.cdisc.org/standards/foundational/adam
- **CDISC Controlled Terminology**: https://evs.nci.nih.gov/ftp1/CDISC/

---

**Framework Version**: 1.0.0  
**Last Updated**: 2025-12-28

# Clinical Database QC Validation Documentation

## Overview

This QC (Quality Control) validation system compares data between **Veeva EDC** (Electronic Data Capture) and the **Clinical Database (CDB)** to ensure data integrity and accuracy during data transfer processes.

## Purpose

The QC programs validate that clinical trial data transferred from Veeva EDC to the Clinical Database is:
- **Complete**: No data is lost during transfer
- **Accurate**: Values match between source and destination
- **Consistent**: Data types and formats are correct
- **Compliant**: Meets regulatory and study protocol requirements

---

## Directory Structure

```
QC/
├── QC Program/
│   ├── Run_All.R           # Main orchestration script
│   ├── Read_All.R          # Data loading utilities
│   ├── AESAE.R             # Adverse Events/Serious AE validation
│   ├── BEBIOMRKR.R         # Biomarker validation
│   ├── BECTDNA.R           # Circulating tumor DNA validation
│   ├── BEDNA.R             # DNA sample validation
│   ├── BERNA.R             # RNA sample validation
│   ├── BETTS.R             # Tissue sample validation
│   ├── CMATM.R             # Anti-tumor medication validation
│   ├── CMGEN.R             # Concomitant medications validation
│   ├── DDGEN.R             # Data dictionary validation
│   ├── DMGEN.R             # Demographics validation
│   ├── DSIC.R              # Informed consent validation
│   ├── DSSTAT.R            # Disposition/Status validation
│   ├── ECGEN.R             # Eligibility criteria validation
│   ├── EGGEN.R             # ECG data validation
│   ├── IEGEN.R             # Inclusion/Exclusion validation
│   ├── ISADA.R             # ADA (Anti-Drug Antibodies) validation
│   ├── LBLOCAL.R           # Local lab results validation
│   ├── MHGEN.R             # Medical history validation
│   ├── MHSDD.R             # Surgical/Device history validation
│   ├── MIPDL1.R            # PD-L1 biomarker validation
│   ├── NRATTQ.R            # Attributions validation
│   ├── NRCOMMONQ.R         # Common queries validation
│   ├── PCSAMPLE.R          # PK sample validation
│   ├── PRATRADI.R          # Prior radiation validation
│   ├── PRATSURG.R          # Prior surgery validation
│   ├── PRGEN.R             # Procedures validation
│   ├── PRPE.R              # Physical examination validation
│   ├── RSECOG.R            # ECOG performance status validation
│   ├── RSEVAL.R            # Response evaluation validation
│   ├── SSLFU.R             # Follow-up validation
│   ├── SUGEN.R             # Substance use validation
│   ├── SVUNSCH.R           # Unscheduled visits validation
│   ├── TUTR.R              # Tumor response validation
│   └── VSGEN.R             # Vital signs validation
└── QC Output/
    └── QC_SUMMARY_REPORT_DDMMMYY.xlsx  # Generated report
```

---

## QC Program Components

### 1. Main Orchestration Script (`Run_All.R`)

**Purpose**: Coordinates the entire QC validation process

**Key Functions**:
- Sets working directory and paths
- Sources data loading utilities
- Executes all domain-specific QC programs
- Creates timestamped Excel workbook
- Saves consolidated QC summary report

**Configuration**:
```r
# Primary path configuration
path_QC <- "D:/Siriyak IMP Data/Desktop/EIK1001_005/QC"
```

### 2. Data Loading Utilities (`Read_All.R`)

**Purpose**: Centralized data import and preparation functions

**Typical Contents**:
- Database connection logic
- Veeva EDC data extraction
- CDB data extraction
- Common data transformations
- Utility functions for comparison

### 3. Domain-Specific QC Programs

Each domain program (e.g., `AESAE.R`, `DMGEN.R`) follows a standard pattern:

**Standard Checks**:
- ✅ **Record Count Validation**: Verify all records transferred
- ✅ **Key Field Matching**: Ensure subject IDs, visit dates match
- ✅ **Value Comparison**: Compare field values between systems
- ✅ **Data Type Validation**: Verify numeric, date, character formats
- ✅ **Missing Data Detection**: Identify unexpected nulls/blanks
- ✅ **Range Checks**: Validate values within acceptable ranges
- ✅ **Referential Integrity**: Check foreign key relationships

**Output**: Each program writes results to a worksheet in the Excel workbook

---

## QC Report Structure

The generated Excel workbook (`QC_SUMMARY_REPORT_DDMMMYY.xlsx`) contains:

### Report Sections

| Worksheet | Domain | Key Validations |
|-----------|--------|----------------|
| AESAE | Adverse Events | Event reporting, severity, causality |
| BEBIOMRKR | Biomarkers | Sample collection, analysis results |
| BECTDNA | ctDNA | Circulating tumor DNA samples |
| BEDNA | DNA Samples | Genetic sample tracking |
| BERNA | RNA Samples | RNA sample processing |
| BETTS | Tissue Samples | Tissue biopsy tracking |
| CMATM | Anti-Tumor Meds | Cancer treatment medications |
| CMGEN | Concomitant Meds | All medications |
| DDGEN | Data Dictionary | Metadata validation |
| DMGEN | Demographics | Subject baseline characteristics |
| DSIC | Informed Consent | Consent documentation |
| DSSTAT | Disposition | Study participation status |
| ECGEN | Eligibility | Inclusion/exclusion criteria |
| EGGEN | ECG | Electrocardiogram data |
| IEGEN | IE Criteria | Specific eligibility assessments |
| ISADA | ADA | Anti-drug antibody testing |
| LBLOCAL | Local Labs | Laboratory results |
| MHGEN | Medical History | Prior/concurrent conditions |
| MHSDD | Surgical History | Prior procedures/devices |
| MIPDL1 | PD-L1 | PD-L1 biomarker expression |
| NRATTQ | Attributions | Event causality assessments |
| NRCOMMONQ | Common Queries | Standard data queries |
| PCSAMPLE | PK Samples | Pharmacokinetic sampling |
| PRATRADI | Prior Radiation | Radiation therapy history |
| PRATSURG | Prior Surgery | Surgical history |
| PRGEN | Procedures | All study procedures |
| PRPE | Physical Exam | Physical examination findings |
| RSECOG | ECOG Status | Performance status |
| RSEVAL | Response Eval | Tumor response assessments |
| SSLFU | Follow-up | Long-term follow-up data |
| SUGEN | Substance Use | Tobacco, alcohol, drugs |
| SVUNSCH | Unscheduled Visits | Off-schedule assessments |
| TUTR | Tumor Response | Tumor measurements, RECIST |
| VSGEN | Vital Signs | Blood pressure, temp, weight |

---

## Execution Instructions

### Prerequisites

1. **R Environment**:
   - R version 4.0 or higher
   - Required packages: `openxlsx`, `dplyr`, `readr`, `DBI`, etc.

2. **Data Access**:
   - Credentials for Veeva EDC database
   - Credentials for Clinical Database
   - Network access to data sources

3. **Directory Setup**:
   - QC Program folder with all validation scripts
   - QC Output folder for report generation

### Running the QC Validation

1. **Open RStudio or R Console**

2. **Update Configuration** (if needed):
   ```r
   # Edit Run_All.R to set correct path
   path_QC <- "YOUR_PATH_HERE"
   ```

3. **Execute Main Script**:
   ```r
   source("QC Program/Run_All.R")
   ```

4. **Monitor Progress**:
   - Watch console for domain processing messages
   - Each domain program will execute sequentially

5. **Review Output**:
   - Check `QC Output/` folder for generated Excel file
   - Filename format: `QC_SUMMARY_REPORT_14Jan26.xlsx`

---

## Interpreting QC Results

### Clean Results (PASS)
- ✅ Record counts match between EDC and CDB
- ✅ No discrepancies in field values
- ✅ All required fields populated
- ✅ Data types consistent

### Discrepancies (REVIEW REQUIRED)
- ⚠️ **Missing Records**: Records in EDC not found in CDB
- ⚠️ **Extra Records**: Records in CDB not in EDC
- ⚠️ **Value Mismatches**: Different values for same field
- ⚠️ **Type Errors**: Data type inconsistencies
- ⚠️ **Missing Values**: Unexpected nulls or blanks

### Action Items
1. Document all discrepancies
2. Investigate root causes (transfer errors, timing, data entry)
3. Coordinate with data management team
4. Resolve issues and re-run QC
5. Archive clean QC report with date lock

---

## Troubleshooting

### Common Issues

#### 1. Script Fails to Source Individual Programs
**Symptom**: Error message "cannot find file 'QC Program/XXXX.R'"

**Solutions**:
- Verify working directory: `getwd()`
- Check file exists: `file.exists("QC Program/AESAE.R")`
- Ensure correct path separator (use `/` not `\`)

#### 2. Database Connection Errors
**Symptom**: "Could not connect to database"

**Solutions**:
- Verify credentials in `Read_All.R`
- Check VPN connection
- Confirm database server is accessible
- Test connection independently

#### 3. Excel File Save Errors
**Symptom**: "Error in saving the workbook"

**Solutions**:
- Close any open Excel files with same name
- Check write permissions on QC Output folder
- Verify disk space available
- Check if file is locked by another process

#### 4. Missing Package Errors
**Symptom**: "there is no package called 'XXXX'"

**Solutions**:
```r
install.packages("openxlsx")
install.packages("dplyr")
install.packages("readr")
```

#### 5. Memory Issues with Large Datasets
**Symptom**: "Cannot allocate vector of size X"

**Solutions**:
```r
# Increase memory limit
memory.limit(size = 16000)  # Windows only
# Or process domains individually
```

---

## Best Practices

### For Clinical Database Programmers

1. **Version Control**:
   - Commit QC programs to Git/SVN
   - Tag releases with study milestone
   - Document any program modifications

2. **Validation**:
   - Test QC programs with subset data first
   - Peer review QC logic before production use
   - Validate against manual spot checks

3. **Documentation**:
   - Comment complex matching logic
   - Document business rules in code
   - Maintain change log

4. **Reproducibility**:
   - Use timestamped outputs
   - Archive QC reports with database locks
   - Document R session info: `sessionInfo()`

5. **Collaboration**:
   - Share QC results with data management
   - Coordinate resolution of discrepancies
   - Communicate issues to stakeholders

---

## Maintenance & Updates

### When to Update QC Programs

- ✏️ **Protocol Amendments**: New forms, fields, or domains
- ✏️ **Database Changes**: Schema updates, new variables
- ✏️ **EDC Updates**: Veeva configuration changes
- ✏️ **Regulatory Changes**: New validation requirements
- ✏️ **Bug Fixes**: Identified issues in QC logic

### Update Process

1. Review change request/amendment
2. Identify affected QC programs
3. Update validation logic
4. Test with historical data
5. Document changes in code comments
6. Update this documentation if needed
7. Obtain peer review and QC approval

---

## Regulatory Compliance

### 21 CFR Part 11 Considerations

- 📋 **Audit Trail**: Document all QC executions
- 📋 **Validation**: Ensure QC programs are validated
- 📋 **Change Control**: Track all modifications
- 📋 **Access Control**: Limit who can modify programs
- 📋 **Training**: Document programmer training on QC process

### Documentation Requirements

- QC execution logs
- Discrepancy resolution records
- QC program validation documentation
- Standard Operating Procedures (SOPs)

---

## Contact & Support

For questions or issues with the QC validation process:

1. **Technical Issues**: Contact Data Management team
2. **Program Logic**: Consult with lead clinical database programmer
3. **Discrepancies**: Coordinate with CDM and clinical operations
4. **Regulatory**: Involve QA and regulatory affairs

---

## Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 14-Jan-2026 | 1.0 | Initial | Created comprehensive QC documentation |

---

## Appendix: R Session Requirements

### Required R Packages

```r
# Core data manipulation
library(dplyr)
library(tidyr)
library(readr)

# Excel output
library(openxlsx)

# Database connectivity
library(DBI)
library(odbc)  # or ROracle, RODBC, etc.

# Date/time handling
library(lubridate)

# String manipulation
library(stringr)
```

### Recommended R Configuration

```r
# Avoid scientific notation
options(scipen = 999)

# Set string handling
options(stringsAsFactors = FALSE)

# Increase output width
options(width = 120)

# Date format
Sys.setlocale("LC_TIME", "English")
```

# Statistical Documentation & Journaling Guide for Clinical Trials

## 📋 Overview

Proper documentation and journaling of statistical work is **critical** for regulatory compliance, reproducibility, and audit trails. This guide covers all documentation requirements from study design through publication.

---

## 📚 Required Statistical Documents

### **1. Statistical Analysis Plan (SAP)**

**When**: Before database lock  
**Purpose**: Pre-specify all statistical analyses  
**Status**: **Required by FDA/EMA**

#### **SAP Contents**

```
1. STUDY OVERVIEW
   - Study objectives
   - Study design
   - Treatment groups
   - Study population

2. SAMPLE SIZE & POWER
   - Sample size calculation
   - Power analysis
   - Assumptions
   - Dropout considerations

3. ANALYSIS POPULATIONS
   - Intent-to-Treat (ITT)
   - Per-Protocol (PP)
   - Safety population
   - Population definitions

4. ENDPOINTS
   - Primary endpoint
   - Secondary endpoints
   - Exploratory endpoints
   - Endpoint definitions

5. STATISTICAL METHODS
   - Primary analysis method
   - Secondary analysis methods
   - Handling of missing data
   - Multiplicity adjustments
   - Subgroup analyses
   - Sensitivity analyses

6. INTERIM ANALYSES
   - Timing
   - Alpha spending
   - Stopping rules

7. CHANGES FROM PROTOCOL
   - Document any deviations
   - Justification

APPENDICES
   - Mock tables/figures
   - Programming specifications
```

#### **SAP Template (R Markdown)**

```r
# Create SAP template
create_sap_template <- function(study_id, protocol) {
  
  sap_content <- glue("
---
title: 'Statistical Analysis Plan'
subtitle: 'Study {study_id}: {protocol}'
author: 'Biostatistics Department'
date: '{Sys.Date()}'
output: 
  pdf_document:
    toc: true
    number_sections: true
---

# Study Overview

## Study Objectives

### Primary Objective
[Describe primary objective]

### Secondary Objectives
[Describe secondary objectives]

## Study Design
- **Design**: [e.g., Randomized, double-blind, placebo-controlled]
- **Duration**: [e.g., 12 weeks treatment + 4 weeks follow-up]
- **Sample Size**: [e.g., 300 subjects (150 per arm)]

# Sample Size and Power

## Sample Size Calculation

```{{r sample-size}}
# Sample size calculation
library(pwr)
pwr.t.test(d = 0.5, sig.level = 0.05, power = 0.80, type = 'two.sample')
```

**Assumptions**:
- Effect size: 0.5 (Cohen's d)
- Alpha: 0.05 (two-sided)
- Power: 80%
- Dropout rate: 15%

**Result**: 64 per group, 128 total (adjusted for dropout: 150 per group)

# Analysis Populations

## Intent-to-Treat (ITT)
All randomized subjects

## Per-Protocol (PP)
ITT subjects without major protocol deviations

## Safety Population
All subjects who received at least one dose

# Endpoints

## Primary Endpoint
Change from baseline in [parameter] at Week 12

## Secondary Endpoints
1. Response rate (≥50% improvement)
2. Time to response
3. Adverse events

# Statistical Methods

## Primary Analysis

**Method**: Mixed Model for Repeated Measures (MMRM)

**Model**:
```
CHG ~ TRT + VISIT + TRT*VISIT + BASE + (1|USUBJID)
```

**Covariance Structure**: Unstructured

**Significance Level**: α = 0.05 (two-sided)

## Missing Data

**Primary**: MMRM (assumes MAR)

**Sensitivity Analyses**:
1. Complete case analysis
2. LOCF
3. Multiple imputation (MICE)
4. Tipping point analysis

## Multiplicity Adjustment

**Method**: Hochberg procedure for secondary endpoints

## Subgroup Analyses

Subgroups (exploratory):
- Age (<65, ≥65)
- Sex (M, F)
- Baseline severity (Mild, Moderate, Severe)

**Method**: Forest plots with interaction tests

# Interim Analyses

**Timing**: After 50% of subjects complete Week 12

**Purpose**: Futility assessment

**Alpha Spending**: Lan-DeMets O'Brien-Fleming

# Tables, Listings, and Figures

## Tables
- Table 14.1.1: Demographics
- Table 14.1.2: Disposition
- Table 14.2.1: Efficacy (Primary Endpoint)
- Table 14.3.1: Adverse Events

## Listings
- Listing 16.2.1: Adverse Events
- Listing 16.2.2: Concomitant Medications

## Figures
- Figure 14.1: Mean Change Over Time
- Figure 14.2: Kaplan-Meier Survival Curves

# Changes from Protocol

[Document any changes and justifications]

# References

[List relevant references]

# Appendices

## Appendix A: Mock Tables
[Include mock table shells]

## Appendix B: Programming Specifications
[Include programming details]

---
**SAP Version**: 1.0  
**Date**: {Sys.Date()}  
**Approved by**: [Name, Title]
  ")
  
  writeLines(sap_content, glue("docs/SAP_{study_id}_v1.0.Rmd"))
  cat("✓ SAP template created: docs/SAP_{study_id}_v1.0.Rmd\n")
}
```

---

### **2. Statistical Programming Log**

**When**: Throughout study  
**Purpose**: Track all programming activities  
**Status**: **Required for audit trail**

#### **Programming Log Template**

```r
# Create programming log
create_programming_log <- function() {
  
  log_template <- tibble(
    Date = as.Date(character()),
    Programmer = character(),
    Script = character(),
    Version = character(),
    Description = character(),
    QC_By = character(),
    QC_Date = as.Date(character()),
    Status = character(),
    Comments = character()
  )
  
  writexl::write_xlsx(log_template, "docs/Programming_Log.xlsx")
  cat("✓ Programming log created: docs/Programming_Log.xlsx\n")
}

# Example entries
programming_log <- tibble(
  Date = c("2024-01-15", "2024-01-20", "2024-02-01"),
  Programmer = c("John Doe", "Jane Smith", "John Doe"),
  Script = c("sdtm_dm.R", "adam_adsl.R", "table_demographics.R"),
  Version = c("1.0", "1.0", "1.0"),
  Description = c(
    "Initial SDTM DM generation",
    "ADSL dataset creation",
    "Demographics table (14.1.1)"
  ),
  QC_By = c("Jane Smith", "John Doe", "Jane Smith"),
  QC_Date = c("2024-01-16", "2024-01-21", "2024-02-02"),
  Status = c("Complete", "Complete", "In Progress"),
  Comments = c("", "Minor formatting changes", "Pending review")
)
```

---

### **3. Analysis Results Metadata (ARM)**

**When**: With TLF outputs  
**Purpose**: Link TLF to analysis datasets  
**Status**: **Required for eCTD submission**

#### **ARM Template**

```r
# Create ARM
create_arm <- function(tlf_outputs, analysis_datasets) {
  
  arm <- tibble(
    Output_ID = character(),
    Output_Type = character(),  # Table, Listing, Figure
    Output_File = character(),
    ICH_E3_Section = character(),
    Title = character(),
    Analysis_Dataset = character(),
    Analysis_Variable = character(),
    Analysis_Method = character(),
    Population = character(),
    Programming_Code = character()
  )
  
  # Example entries
  arm <- tibble(
    Output_ID = c("T-14.1.1", "T-14.3.1", "L-16.2.1", "F-14.4"),
    Output_Type = c("Table", "Table", "Listing", "Figure"),
    Output_File = c(
      "Table_14_1_1_Demographics.rtf",
      "Table_14_3_1_AE_Summary.rtf",
      "Listing_16_2_1_AE.rtf",
      "Figure_14_4_KM_Survival.png"
    ),
    ICH_E3_Section = c("14.1.1", "14.3.1", "16.2.1", "14.4"),
    Title = c(
      "Demographics and Baseline Characteristics",
      "Adverse Events Summary",
      "Adverse Events Listing",
      "Kaplan-Meier Survival Curves"
    ),
    Analysis_Dataset = c("ADSL", "ADAE", "ADAE", "ADSL"),
    Analysis_Variable = c("AGE, SEX, RACE", "AEDECOD", "All", "AVAL"),
    Analysis_Method = c("Descriptive", "Frequency", "N/A", "Kaplan-Meier"),
    Population = c("Safety", "Safety", "Safety", "ITT"),
    Programming_Code = c(
      "R/tlf/table_demographics.R",
      "R/tlf/table_ae_summary.R",
      "R/tlf/listing_ae.R",
      "R/tlf/figure_km_survival.R"
    )
  )
  
  writexl::write_xlsx(arm, "docs/Analysis_Results_Metadata.xlsx")
  cat("✓ ARM created: docs/Analysis_Results_Metadata.xlsx\n")
  
  return(arm)
}
```

---

### **4. Statistical Review Memo**

**When**: After analysis completion  
**Purpose**: Summarize key findings for review  
**Status**: **Internal document**

#### **Review Memo Template**

```markdown
# Statistical Review Memo

**Study**: [Study ID]  
**Protocol**: [Protocol Number]  
**Date**: [Date]  
**Statistician**: [Name]

## Executive Summary

[Brief summary of key findings]

## Study Design

- **Design**: [e.g., Randomized, double-blind, placebo-controlled]
- **Sample Size**: [Planned vs. Actual]
- **Duration**: [Treatment period]

## Analysis Populations

| Population | N | % of Randomized |
|------------|---|-----------------|
| ITT | 150 | 100% |
| Safety | 148 | 98.7% |
| Per-Protocol | 142 | 94.7% |

## Primary Endpoint

**Endpoint**: Change from baseline in [parameter] at Week 12

**Result**:
- Treatment: -5.2 (SD 3.1)
- Placebo: -2.1 (SD 2.8)
- Difference: -3.1 (95% CI: -4.2, -2.0)
- P-value: <0.001

**Conclusion**: Statistically significant and clinically meaningful improvement

## Secondary Endpoints

[Summarize secondary endpoint results]

## Safety

**Adverse Events**:
- Any AE: Treatment 65%, Placebo 58%
- Serious AE: Treatment 3%, Placebo 2%
- Discontinuation due to AE: Treatment 5%, Placebo 3%

**Conclusion**: Acceptable safety profile

## Subgroup Analyses

[Summarize subgroup findings]

## Sensitivity Analyses

[Summarize sensitivity analysis results]

## Deviations from SAP

[Document any deviations and justifications]

## Conclusions

[Overall conclusions and recommendations]

---
**Prepared by**: [Name, Title]  
**Reviewed by**: [Name, Title]  
**Date**: [Date]
```

---

### **5. Data Monitoring Committee (DMC) Reports**

**When**: At interim analyses  
**Purpose**: Inform DMC of study progress  
**Status**: **Required for studies with DMC**

#### **DMC Report Structure**

```markdown
# Data Monitoring Committee Report

**Study**: [Study ID]  
**Interim Analysis**: [Number]  
**Data Cut-off**: [Date]  
**Report Date**: [Date]

## CONFIDENTIAL - DMC ONLY

## Enrollment

- **Target**: 300
- **Enrolled**: 180 (60%)
- **Completed**: 120 (40%)

## Safety Summary

### Adverse Events (Unblinded)

| Treatment | Any AE | Serious AE | Fatal AE |
|-----------|--------|------------|----------|
| Active | 45/90 (50%) | 3/90 (3.3%) | 0 |
| Placebo | 38/90 (42%) | 2/90 (2.2%) | 0 |

### Safety Signals

[Describe any safety concerns]

## Efficacy Summary (Unblinded)

[Present interim efficacy results]

## Futility Analysis

**Conditional Power**: [Calculate]

**Recommendation**: Continue / Stop for futility

## Recommendations

[DMC recommendations]

---
**Prepared by**: [Unblinded Statistician]  
**Date**: [Date]
```

---

## 📝 Daily Statistical Journal

### **Purpose**

Document daily statistical activities for:
- Audit trail
- Reproducibility
- Knowledge transfer
- Regulatory compliance

### **Journal Template**

```r
# Create daily journal entry
create_journal_entry <- function(date = Sys.Date()) {
  
  journal_entry <- glue("
# Statistical Journal Entry - {date}

## Activities

### Data Processing
- [ ] SDTM generation
- [ ] ADaM generation
- [ ] Data validation

### Analysis
- [ ] Primary analysis
- [ ] Secondary analyses
- [ ] Sensitivity analyses

### Programming
- [ ] New scripts developed
- [ ] Scripts updated
- [ ] QC performed

### Meetings
- [ ] Team meetings
- [ ] Regulatory discussions
- [ ] DMC meetings

## Detailed Notes

### Morning (9:00 - 12:00)
[Describe activities]

### Afternoon (13:00 - 17:00)
[Describe activities]

## Issues Encountered

1. [Issue 1]
   - **Problem**: [Description]
   - **Solution**: [How resolved]
   - **Impact**: [Any impact on timeline/results]

## Decisions Made

1. [Decision 1]
   - **Context**: [Why decision needed]
   - **Decision**: [What was decided]
   - **Rationale**: [Justification]
   - **Approved by**: [Name]

## Action Items

- [ ] [Action 1] - Due: [Date] - Owner: [Name]
- [ ] [Action 2] - Due: [Date] - Owner: [Name]

## Files Modified

| File | Version | Description |
|------|---------|-------------|
| sdtm_dm.R | 1.1 | Added new derivation |
| table_demographics.R | 1.0 | Initial creation |

## QC Activities

| Script | QC By | Status | Comments |
|--------|-------|--------|----------|
| sdtm_dm.R | Jane Smith | Pass | Minor formatting |

## Next Steps

Tomorrow's priorities:
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

---
**Statistician**: [Name]  
**Date**: {date}  
**Hours Worked**: [Hours]
  ")
  
  # Save journal entry
  journal_file <- glue("docs/journal/Journal_{format(date, '%Y%m%d')}.md")
  dir.create("docs/journal", recursive = TRUE, showWarnings = FALSE)
  writeLines(journal_entry, journal_file)
  
  cat(glue("✓ Journal entry created: {journal_file}\n"))
}
```

---

## 📊 Version Control & Change Log

### **Git Commit Messages**

Follow structured format:

```bash
# Good commit messages
git commit -m "feat(sdtm): Add SDTM DM domain generation"
git commit -m "fix(adam): Correct CHG calculation in ADLB"
git commit -m "docs(sap): Update SAP with protocol amendment"
git commit -m "refactor(tlf): Improve table formatting function"

# Commit message format
<type>(<scope>): <subject>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- refactor: Code refactoring
- test: Testing
- chore: Maintenance
```

### **Change Log**

```r
# Maintain CHANGELOG.md
changelog_entry <- glue("
# Changelog

## [1.1.0] - 2024-02-15

### Added
- MMRM analysis for repeated measures
- Multiple imputation for missing data
- Kaplan-Meier survival analysis

### Changed
- Updated ADSL to include new population flags
- Improved table formatting in demographics table

### Fixed
- Corrected CHG calculation in ADLB
- Fixed date format in AE listing

### Deprecated
- Old LOCF method (replaced with MMRM)

## [1.0.0] - 2024-01-15

### Added
- Initial SDTM generation (10 domains)
- Initial ADaM generation (6 datasets)
- Basic TLF outputs
")
```

---

## 🔍 Audit Trail Requirements

### **What to Document**

1. **All Analyses**
   - Date performed
   - Analyst name
   - Software version
   - Input data version
   - Output files

2. **All Decisions**
   - What was decided
   - Who decided
   - When decided
   - Rationale

3. **All Changes**
   - What changed
   - Why changed
   - Who approved
   - Impact assessment

### **Audit Trail Template**

```r
# Create audit trail
audit_trail <- tibble(
  Timestamp = Sys.time(),
  User = Sys.info()["user"],
  Action = "Analysis Executed",
  Script = "R/adam/adam_adsl.R",
  Version = "1.0",
  Input_Data = "data/sdtm/dm.sas7bdat (v1.0)",
  Output_Data = "data/adam/adsl.sas7bdat (v1.0)",
  Status = "Success",
  Comments = "Initial ADSL generation"
)

# Append to audit log
audit_log_file <- "docs/Audit_Trail.xlsx"
if (file.exists(audit_log_file)) {
  existing_log <- readxl::read_excel(audit_log_file)
  audit_trail <- bind_rows(existing_log, audit_trail)
}
writexl::write_xlsx(audit_trail, audit_log_file)
```

---

## 📅 Timeline & Milestones

### **Statistical Activities Timeline**

```r
# Create study timeline
study_timeline <- tibble(
  Milestone = c(
    "SAP Finalization",
    "Database Lock",
    "SDTM Generation",
    "ADaM Generation",
    "TLF Generation",
    "Statistical Review",
    "QC Complete",
    "Submission Package"
  ),
  Planned_Date = as.Date(c(
    "2024-01-15",
    "2024-02-01",
    "2024-02-05",
    "2024-02-10",
    "2024-02-20",
    "2024-02-25",
    "2024-03-01",
    "2024-03-15"
  )),
  Actual_Date = as.Date(NA),
  Status = c(
    "Complete",
    "Complete",
    "Complete",
    "In Progress",
    "Not Started",
    "Not Started",
    "Not Started",
    "Not Started"
  ),
  Owner = c(
    "Biostatistics",
    "Data Management",
    "Programming",
    "Programming",
    "Programming",
    "Biostatistics",
    "QC Team",
    "Regulatory Affairs"
  )
)
```

---

## 📖 Best Practices

### **Documentation Standards**

1. ✅ **Write SAP before database lock**
2. ✅ **Document all deviations from SAP**
3. ✅ **Maintain daily journal**
4. ✅ **Use version control (Git)**
5. ✅ **Keep audit trail**
6. ✅ **QC all outputs**
7. ✅ **Archive all versions**

### **File Naming Conventions**

```
# Documents
SAP_STUDY001_v1.0_2024-01-15.pdf
DMC_Report_Interim1_2024-02-01.pdf
Statistical_Review_Memo_2024-03-01.pdf

# Code
sdtm_dm_v1.0.R
adam_adsl_v1.1.R
table_demographics_v1.0.R

# Data
dm_v1.0_2024-02-01.sas7bdat
adsl_v1.0_2024-02-10.sas7bdat

# Outputs
Table_14_1_1_Demographics_v1.0.rtf
Figure_14_4_KM_Survival_v1.0.png
```

---

## 🎯 Summary

### **Essential Documents**

| Document | When | Required By | Purpose |
|----------|------|-------------|---------|
| **SAP** | Before DBL | FDA/EMA | Pre-specify analyses |
| **Programming Log** | Ongoing | Audit | Track activities |
| **ARM** | With TLF | eCTD | Link outputs to data |
| **Review Memo** | After analysis | Internal | Summarize findings |
| **DMC Reports** | At interims | DMC | Safety monitoring |
| **Daily Journal** | Daily | Audit | Activity log |
| **Audit Trail** | Ongoing | Regulatory | Compliance |

### **Key Takeaways**

✅ **Document everything** - If it's not documented, it didn't happen  
✅ **Version control** - Track all changes  
✅ **Pre-specify** - Write SAP before analysis  
✅ **Maintain logs** - Daily journal + programming log  
✅ **QC everything** - Independent review required  
✅ **Archive properly** - Keep all versions  

---

**This comprehensive documentation ensures regulatory compliance, reproducibility, and successful submissions!** 📋✅

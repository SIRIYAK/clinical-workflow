# Biostatistician Module - Complete Guide

## Overview

This module provides advanced biostatistician tools that complement the core SDTM/ADaM/TLF framework. It includes study design utilities, advanced statistical models, and missing data handling.

---

## Module Structure

```
R/biostat/
├── study_design/
│   ├── sample_size_calculations.R
│   └── randomization_utilities.R
├── advanced_models/
│   └── advanced_statistical_models.R
└── missing_data/
    └── missing_data_imputation.R
```

---

## Components

### 1. Sample Size & Power Calculations

**Script**: `R/biostat/study_design/sample_size_calculations.R`

**Capabilities**:
- Two-sample t-test sample size
- Two-proportion test sample size
- Survival analysis sample size (time-to-event)
- One-way ANOVA sample size
- Power curve generation
- Group sequential design (interim analyses)

**Usage**:
```r
source("R/biostat/study_design/sample_size_calculations.R")
```

**Output**:
- `outputs/biostat/Sample_Size_Summary.xlsx`
- `outputs/biostat/Power_Curve.png`

### 2. Randomization Utilities

**Script**: `R/biostat/study_design/randomization_utilities.R`

**Capabilities**:
- Simple randomization
- Block randomization
- Stratified randomization
- Adaptive randomization (minimization)
- Randomization verification

**Usage**:
```r
source("R/biostat/study_design/randomization_utilities.R")
```

**Output**:
- `outputs/biostat/Randomization_Schemes.xlsx`

### 3. Advanced Statistical Models

**Script**: `R/biostat/advanced_models/advanced_statistical_models.R`

**Capabilities**:
- **MMRM** (Mixed Model for Repeated Measures)
- **Linear Mixed Effects Models**
- **GLMM** (Generalized Linear Mixed Models)
- **Repeated Measures ANOVA**
- LS Means estimation
- Model diagnostics

**Usage**:
```r
source("R/biostat/advanced_models/advanced_statistical_models.R")
```

**Output**:
- `outputs/biostat/MMRM_Results.xlsx`
- `outputs/biostat/MMRM_LSMeans_Plot.png`
- `outputs/biostat/MMRM_Diagnostics.png`

### 4. Missing Data Imputation

**Script**: `R/biostat/missing_data/missing_data_imputation.R`

**Capabilities**:
- Missing data pattern analysis
- **Multiple Imputation (MICE)**
- Sensitivity analyses:
  - Complete Case Analysis (CCA)
  - Last Observation Carried Forward (LOCF)
  - Worst case imputation
  - Best case imputation
- **Tipping point analysis**

**Usage**:
```r
source("R/biostat/missing_data/missing_data_imputation.R")
```

**Output**:
- `outputs/biostat/Missing_Data_Summary.xlsx`
- `outputs/biostat/MI_Pooled_Results.xlsx`
- `outputs/biostat/Sensitivity_Analysis_Summary.xlsx`
- `outputs/biostat/Tipping_Point_Analysis.png`

---

## Statistical Methods Covered

### Study Design
✅ Sample size calculations (t-test, proportions, survival, ANOVA)  
✅ Power analysis and curves  
✅ Group sequential designs  
✅ Randomization schemes  

### Advanced Models
✅ MMRM (primary analysis for repeated measures)  
✅ Linear mixed effects models  
✅ Generalized linear mixed models (binary outcomes)  
✅ Repeated measures ANOVA  
✅ LS Means with confidence intervals  

### Missing Data
✅ Multiple imputation (MICE)  
✅ Sensitivity analyses (CCA, LOCF, worst/best case)  
✅ Tipping point analysis  
✅ Pattern analysis and visualization  

---

## Typical Workflow

### Phase 1: Study Design
```r
# Calculate sample size
source("R/biostat/study_design/sample_size_calculations.R")

# Generate randomization scheme
source("R/biostat/study_design/randomization_utilities.R")
```

### Phase 2: Data Collection
*(Use main SDTM/ADaM framework)*

### Phase 3: Primary Analysis
```r
# MMRM for repeated measures endpoint
source("R/biostat/advanced_models/advanced_statistical_models.R")
```

### Phase 4: Sensitivity Analysis
```r
# Handle missing data
source("R/biostat/missing_data/missing_data_imputation.R")
```

---

## Integration with Main Framework

The biostatistician module integrates seamlessly with the main framework:

```
Study Design (Biostat Module)
    ↓
Data Collection
    ↓
SDTM Generation (Main Framework)
    ↓
ADaM Generation (Main Framework)
    ↓
Advanced Analysis (Biostat Module)
    ↓
TLF Generation (Main Framework)
    ↓
Validation (Main Framework)
    ↓
Submission (Main Framework)
```

---

## Required R Packages

### Study Design
- `pwr` - Power calculations
- `powerSurvEpi` - Survival sample size
- `gsDesign` - Group sequential designs
- `blockrand` - Randomization

### Advanced Models
- `nlme` - Linear mixed effects
- `lme4` - Mixed models
- `lmerTest` - Mixed model tests
- `emmeans` - LS Means estimation

### Missing Data
- `mice` - Multiple imputation
- `mitools` - MI analysis tools
- `VIM` - Visualization of missing data

---

## Examples

### Example 1: Sample Size for Continuous Endpoint

```r
source("R/biostat/study_design/sample_size_calculations.R")

# Calculate for medium effect size
calculate_ttest_sample_size(
  effect_size = 0.5,
  alpha = 0.05,
  power = 0.80
)
# Result: ~64 per group, 128 total
```

### Example 2: MMRM Analysis

```r
source("R/biostat/advanced_models/advanced_statistical_models.R")

# MMRM is automatically run on ADLB data
# Results saved to outputs/biostat/MMRM_Results.xlsx
```

### Example 3: Multiple Imputation

```r
source("R/biostat/missing_data/missing_data_imputation.R")

# Multiple imputation with 5 datasets
# Pooled results saved to outputs/biostat/MI_Pooled_Results.xlsx
```

---

## Best Practices

### Sample Size Calculations
- Always justify effect size assumptions
- Consider dropout rates (inflate by 10-20%)
- Document all assumptions
- Perform sensitivity analyses on key parameters

### Randomization
- Use block randomization for balance
- Stratify on key prognostic factors
- Keep randomization list secure
- Verify balance after enrollment

### Advanced Models
- Check model assumptions (residuals, normality)
- Report LS Means with 95% CI
- Include model diagnostics in appendix
- Consider sensitivity to model specification

### Missing Data
- Always perform sensitivity analyses
- Use multiple imputation as primary
- Report complete case as sensitivity
- Perform tipping point analysis for key endpoints

---

## Regulatory Considerations

### FDA Expectations
- **Sample size**: Justify with power calculations
- **Randomization**: Document scheme and verification
- **MMRM**: Preferred for repeated measures
- **Missing data**: Multiple sensitivity analyses required

### Documentation Required
- Statistical Analysis Plan (SAP)
- Sample size justification
- Randomization plan
- Missing data handling plan
- Sensitivity analysis results

---

## Summary

This biostatistician module provides:

✅ **Complete study design tools**  
✅ **Advanced statistical models** (MMRM, mixed models)  
✅ **Comprehensive missing data handling**  
✅ **Regulatory-compliant methods**  
✅ **Integration with main framework**  

**Total Scripts**: 4  
**Statistical Methods**: 15+  
**Output Files**: 10+  

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-28

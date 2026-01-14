# Statistical Analysis TLF Summary

## 📊 Complete TLF Framework - 20 Scripts

### **Tables (7)**

| # | Script | ICH E3 | Description |
|---|--------|--------|-------------|
| 1 | `table_demographics.R` | 14.1.1 | Demographics and baseline characteristics |
| 2 | `table_disposition.R` | 14.1.2 | Subject disposition and discontinuation |
| 3 | `table_vital_signs.R` | 14.2.1 | Vital signs summary statistics |
| 4 | `table_ae_summary.R` | 14.3.1 | Adverse events summary |
| 5 | `table_ae_by_soc.R` | 14.3.2 | AE by System Organ Class and Preferred Term |
| 6 | `table_lab_shift.R` | 14.3.5 | Laboratory shift tables (baseline to post-baseline) |
| 7 | `table_anova_lab.R` | 14.5 | ANOVA for laboratory parameters |

### **Listings (3)**

| # | Script | ICH E3 | Description |
|---|--------|--------|-------------|
| 1 | `listing_ae.R` | 16.2.1 | Adverse events listing |
| 2 | `listing_cm.R` | 16.2.2 | Concomitant medications listing |
| 3 | `listing_lab.R` | 16.2.3 | Laboratory test results listing |

### **Figures (7)**

| # | Script | Description | Analysis Type |
|---|--------|-------------|---------------|
| 1 | `figure_lab_boxplot.R` | Box plots for lab change from baseline | Descriptive |
| 2 | `figure_ae_barchart.R` | AE incidence bar chart | Descriptive |
| 3 | `figure_mean_change_time.R` | Mean change over time (line plots) | Longitudinal |
| 4 | `figure_km_survival.R` | **Kaplan-Meier survival curves** | **Survival Analysis** |
| 5 | `figure_forest_plot.R` | **Forest plot for subgroup analysis** | **Meta-analysis** |
| 6 | `figure_waterfall_plot.R` | **Waterfall plot for tumor response** | **Efficacy** |
| 7 | `figure_swimmer_plot.R` | **Swimmer plot for treatment duration** | **Longitudinal** |

### **Infrastructure (3)**

| # | Script | Purpose |
|---|--------|---------|
| 1 | `tlf_utilities.R` | Core TLF generation functions |
| 2 | `generate_all_tlf.R` | Master TLF orchestrator |
| 3 | `README.md` | Complete documentation |

---

## 🎯 Statistical Methods Covered

### ✅ **Descriptive Statistics**
- Summary statistics (mean, SD, median, min, max)
- Frequency tables with percentages
- Cross-tabulations

### ✅ **Inferential Statistics**
- **ANOVA**: One-way ANOVA for continuous endpoints
- **Pairwise comparisons**: Bonferroni-adjusted p-values
- **LS Means**: Least squares means with standard errors

### ✅ **Survival Analysis**
- **Kaplan-Meier curves**: Survival probability over time
- **Log-rank test**: Treatment group comparison
- **Median survival**: With 95% confidence intervals
- **Risk tables**: Number at risk at each time point

### ✅ **Subgroup Analysis**
- **Forest plots**: Treatment effects across subgroups
- **Odds ratios**: With 95% confidence intervals
- **Interaction tests**: Subgroup × treatment interactions

### ✅ **Efficacy Analysis**
- **Waterfall plots**: Best response visualization
- **Response rates**: CR, PR, SD, PD classification
- **Swimmer plots**: Treatment duration and key events

---

## 📈 Output Formats

### **Tables**
- **RTF**: Regulatory submission format
- **DOCX**: Internal review and collaboration
- **XLSX**: Data tables for detailed review

### **Figures**
- **PNG**: High-resolution (300 DPI) for presentations
- **PDF**: Vector format for publications
- **TIFF**: Regulatory submission format (300 DPI, LZW compression)

---

## 🚀 Usage

### **Generate All TLF Outputs**
```r
source("R/tlf/generate_all_tlf.R")
```

### **Generate Specific Categories**
```r
# Tables only
source("R/tlf/table_demographics.R")
source("R/tlf/table_anova_lab.R")

# Figures only
source("R/tlf/figure_km_survival.R")
source("R/tlf/figure_forest_plot.R")

# Listings only
source("R/tlf/listing_ae.R")
```

---

## 📊 Advanced Statistical Features

### **Kaplan-Meier Analysis**
- Survival curves with confidence bands
- Risk tables showing number at risk
- Log-rank test p-value
- Median survival with 95% CI
- Censoring indicators

### **ANOVA Tables**
- F-statistics and p-values
- Least squares means by treatment
- Standard errors
- Pairwise comparisons (Bonferroni-adjusted)
- Significance indicators

### **Forest Plots**
- Odds ratios with 95% CI
- Subgroup analysis (age, sex, race)
- Overall treatment effect
- Graphical representation of heterogeneity

### **Waterfall Plots**
- Best percentage change from baseline
- Response thresholds (PR: -30%, PD: +20%)
- Color-coded by response category
- Individual subject bars

### **Swimmer Plots**
- Treatment duration bars
- Response markers (▼)
- Progression markers (X)
- Ongoing treatment indicators (●)
- Ordered by duration

---

## 🎨 Visualization Standards

All figures follow publication-quality standards:
- **Fonts**: Clear, readable (10-14pt)
- **Colors**: Color-blind friendly palettes
- **Resolution**: 300 DPI minimum
- **Legends**: Descriptive and positioned appropriately
- **Titles**: Informative with subtitles
- **Captions**: Generation date and key information
- **Axes**: Properly labeled with units

---

## 📦 Integration with Framework

```
Raw SAS Data (39 files)
    ↓
SDTM Domains (10) → XPT/SAS/CSV
    ↓
ADaM Datasets (6) → XPT/SAS/CSV
    ↓
TLF Outputs (20 scripts) → RTF/DOCX/PDF/PNG/TIFF
    ├── Tables (7)
    ├── Listings (3)
    └── Figures (7)
    ↓
OFS Package → Regulatory Submission Ready
```

---

## 📝 Regulatory Compliance

- ✅ **ICH E3 Guidelines**: Structure and numbering
- ✅ **CDISC Standards**: Variable names and terminology
- ✅ **FDA Guidance**: Statistical analysis presentation
- ✅ **EMA Guidelines**: Clinical trial reporting
- ✅ **Reproducibility**: All code documented and versioned

---

**Framework Version**: 1.0.0  
**Total Scripts**: 35+ (SDTM + ADaM + BDM + TLF + Analysis)  
**Last Updated**: 2025-12-28

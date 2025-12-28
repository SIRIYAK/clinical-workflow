# TLF (Tables, Listings, Figures) Generation Framework

## Overview

This directory contains scripts for generating regulatory-compliant Tables, Listings, and Figures (TLF) for clinical study reports following ICH E3 guidelines.

## Directory Structure

```
R/tlf/
├── tlf_utilities.R           # Core TLF generation functions
├── generate_all_tlf.R         # Master TLF orchestrator
├── table_demographics.R       # Table 14.1.1: Demographics
├── table_ae_summary.R         # Table 14.3.1: AE Summary
├── listing_ae.R               # Listing 16.2.1: AE Listing
└── ... (additional TLF scripts)
```

## Quick Start

### Generate All TLF Outputs
```r
source("R/tlf/generate_all_tlf.R")
```

### Generate Individual Outputs
```r
# Demographics table
source("R/tlf/table_demographics.R")

# AE summary table
source("R/tlf/table_ae_summary.R")

# AE listing
source("R/tlf/listing_ae.R")
```

## Output Formats

### Tables
- **RTF**: For regulatory submission
- **DOCX**: For internal review
- **Location**: `outputs/tlf/tables/`

### Listings
- **RTF**: Courier New font, regulatory format
- **Location**: `outputs/tlf/listings/`

### Figures
- **PNG**: High-resolution (300 DPI)
- **PDF**: Vector format
- **TIFF**: Regulatory submission format
- **Location**: `outputs/tlf/figures/`

## Available TLF Outputs

### Tables (ICH E3 Section 14)

#### 14.1 Demographics and Baseline Characteristics
- **Table 14.1.1**: Demographics (Age, Sex, Race, Ethnicity)
  - Script: `table_demographics.R`
  - Population: Safety
  - By: Treatment Group

#### 14.3 Adverse Events
- **Table 14.3.1**: AE Summary
  - Script: `table_ae_summary.R`
  - Categories: Any AE, Serious, Severe, Related, Leading to Discontinuation, Fatal
  - Population: Safety
  - By: Treatment Group

### Listings (ICH E3 Section 16)

#### 16.2 Adverse Events
- **Listing 16.2.1**: Adverse Events
  - Script: `listing_ae.R`
  - Includes: Subject ID, AE Term, Dates, Severity, Outcome, Causality
  - Sort: Treatment, Subject, Date

## TLF Utilities

The `tlf_utilities.R` script provides core functions:

### Table Functions
- `create_regulatory_table()`: Create formatted table with title and footnotes
- `export_table_rtf()`: Export table to RTF format
- `export_table_docx()`: Export table to DOCX format

### Statistical Functions
- `summarize_continuous()`: Summary stats for continuous variables
- `summarize_categorical()`: Frequency tables for categorical variables
- `format_pvalue()`: Format p-values for regulatory tables

### Listing Functions
- `create_listing()`: Create data listing with standard formatting
- `export_listing_rtf()`: Export listing to RTF format

### Figure Functions
- `save_figure()`: Save figure in multiple formats (PNG, PDF, TIFF)

## Customization

### Adding New Tables

1. Create new script in `R/tlf/` (e.g., `table_disposition.R`)
2. Follow this template:

```r
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

# Read ADaM datasets
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat"))

# Create summary
summary_data <- adsl %>%
  # Your analysis code here
  
# Create table
table_ft <- create_regulatory_table(
  data = summary_data,
  title = "Your Table Title",
  footnotes = c("Footnote 1", "Footnote 2")
)

# Export
export_table_rtf(table_ft, "Table_XX_X_X_Name")
```

3. Add to `generate_all_tlf.R`

### Adding New Listings

Similar process, use `create_listing()` instead of `create_regulatory_table()`

### Adding New Figures

Use ggplot2 for plotting and `save_figure()` for export:

```r
library(ggplot2)

plot <- ggplot(data, aes(x, y)) +
  geom_point() +
  theme_minimal()

save_figure(plot, "Figure_XX_X_X_Name", width = 8, height = 6)
```

## Standards Compliance

All TLF outputs follow:
- **ICH E3 Guidelines**: Structure and numbering
- **CDISC Standards**: Variable names and terminology
- **Regulatory Requirements**: Formatting and presentation

### Table Standards
- Font: Times New Roman, 9pt
- Borders: Top and bottom only
- Alignment: Left for text, center for numbers
- Footnotes: Italicized, 8pt

### Listing Standards
- Font: Courier New, 8pt
- Monospaced for alignment
- Sorted by treatment, subject, date

### Figure Standards
- Resolution: 300 DPI minimum
- Format: TIFF for submission
- Size: 8" x 6" (adjustable)

## Integration with Analysis Framework

TLF generation is part of the complete workflow:

```
Raw SAS Data
    ↓
SDTM Domains
    ↓
ADaM Datasets
    ↓
TLF Outputs  ← YOU ARE HERE
    ↓
OFS Package
```

## Prerequisites

TLF generation requires:
1. ✅ ADaM datasets generated (especially ADSL)
2. ✅ Required R packages installed
3. ✅ Output directories created

## Troubleshooting

### Issue: Missing ADaM Datasets
```r
# Generate ADaM datasets first
source("R/run_all.R")  # Or run ADaM scripts individually
```

### Issue: Font Not Found
```r
# Install required fonts on your system
# Windows: Times New Roman and Courier New are usually pre-installed
```

### Issue: Large Tables Don't Fit
```r
# Adjust font size in create_regulatory_table()
# Or split into multiple tables
```

## Next Steps

1. **Generate TLF Outputs**:
   ```r
   source("R/tlf/generate_all_tlf.R")
   ```

2. **Review Outputs**:
   - Check `outputs/tlf/tables/` for tables
   - Check `outputs/tlf/listings/` for listings
   - Check `outputs/tlf/figures/` for figures

3. **Prepare OFS Package**:
   ```r
   source("R/analysis/prepare_ofs.R")
   ```

4. **Customize as Needed**:
   - Add study-specific tables
   - Modify formatting
   - Add additional analyses

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-28

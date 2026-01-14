# R Data Validation Checks (Rchecks)

## Overview

This folder contains R-based data validation checks for the DQCC Study CDB data transfer and quality control. The validation framework includes **preprocessing**, **validation checks**, and **post-processing** phases to ensure comprehensive data quality assessment.

**Author**: Siriyak  
**Date**: 2026-01-14  
**Study**: DQCCStudy  
**Compound**: Compound_A

---

## Purpose

The Rchecks framework provides:

1. **CDB Migration Validation**: Compare ALSC and CDB dataset repositories to identify structural differences
2. **Data Quality Checks**: Identify data issues including missing values, duplicates, outliers, and inconsistencies
3. **Automated Reporting**: Generate comprehensive Excel reports with validation results
4. **Reusable Functions**: Comparison and validation functions for custom analysis

---

## Folder Structure

```
Rchecks/
├── README.md                          # This file
├── config.R                           # Configuration and study parameters
├── utils.R                            # Common utility functions
├── 00_preprocessing.R                 # Preprocessing: data loading & setup
├── 01_CDB_Migration_Comparison.R      # CDB vs ALSC comparison
├── 02_Data_Quality_Checks.R           # Data quality validation
├── 03_Compare_Tool_Functions.R        # Dataset comparison functions
├── 99_postprocessing.R                # Post-processing & reporting
└── run_all_checks.R                   # Master execution script
```

---

## Quick Start

### Running All Validation Checks

The simplest way to run all validation checks is to execute the master script:

```r
# Set working directory to Rchecks folder
setwd("d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/Rchecks")

# Run all validation checks
source("run_all_checks.R")
```

This will:
1. Load all required packages
2. Run preprocessing (data loading)
3. Execute CDB migration comparison
4. Execute data quality checks
5. Generate consolidated reports
6. Print summary to console

### Custom Execution

You can customize which checks to run:

```r
# Load the framework
source("run_all_checks.R")

# Run only migration comparison
validation_results <- run_all_validation_checks(
  run_migration = TRUE, 
  run_quality = FALSE
)

# Run only data quality checks on ALSC data
validation_results <- run_all_validation_checks(
  run_migration = FALSE,
  run_quality = TRUE,
  quality_target = "alsc"
)
```

---

## Validation Workflow

### Phase 1: Preprocessing (`00_preprocessing.R`)

**Purpose**: Initialize validation environment and load datasets

**Functions**:
- `run_preprocessing()`: Main preprocessing function
- `load_cdb_library()`: Load CDB datasets
- `load_alsc_library()`: Load ALSC datasets
- `prepare_comparison_metadata()`: Create dataset comparison metadata

**Outputs**:
- List of CDB datasets (with `cdb_` prefix)
- List of ALSC datasets (with `inf_` prefix)
- Metadata about common and missing datasets

---

### Phase 2: Validation Checks

#### CDB Migration Comparison (`01_CDB_Migration_Comparison.R`)

**Purpose**: Compare ALSC and CDB datasets to identify migration issues

**Checks**:
- Datasets missing in CDB or ALSC
- Variables missing in CDB
- Variable type and length mismatches
- Observation count differences

**Main Function**: `execute_cdb_migration_check(preprocessing_results)`

**Output Report**: `cdb_migration_summary_[DATE].xlsx`

**Report Sheets**:
- `missing_ds_in_cdb_summary`: Datasets only in ALSC
- `missing_ds_in_alsc_summary`: Datasets only in CDB
- `var_not_in_cdb`: Variables missing in CDB
- `var_in_cdb`: Variable metadata comparison with mismatch flags
- `obs_summary`: Observation count comparison

---

#### Data Quality Checks (`02_Data_Quality_Checks.R`)

**Purpose**: Identify data quality issues within datasets

**Checks**:
1. **Missing Values**: Variables with missing data and percentages
2. **Duplicates**: Duplicate records based on key variables
3. **Date Consistency**: Invalid date formats
4. **Data Types**: Mixed numeric/character data
5. **Outliers**: Statistical outliers using IQR method

**Main Function**: `execute_data_quality_checks(preprocessing_results, check_cdb = TRUE)`

**Output Report**: `data_quality_report_[DATE].xlsx`

**Report Sheets**:
- `missing_values`: Variables with missing data
- `duplicates`: Datasets with duplicate records
- `date_issues`: Date format problems
- `type_issues`: Data type inconsistencies
- `outliers`: Statistical outliers by variable

---

### Phase 3: Post-Processing (`99_postprocessing.R`)

**Purpose**: Aggregate results and generate final reports

**Functions**:
- `run_postprocessing(all_results)`: Main post-processing function
- `aggregate_validation_results()`: Combine all check results
- `create_executive_summary()`: Generate high-level summary
- `generate_final_report()`: Create consolidated Excel report
- `print_validation_summary()`: Display summary in console

**Output Report**: `validation_final_report_[DATE].xlsx`

**Report Sheets**:
- `Executive_Summary`: Overall validation status
- `Migration_Summary`: Migration check summary
- `Quality_Summary`: Quality check summary
- Detailed sheets for all issues found

---

## Configuration

Edit `config.R` to customize:

### Study Parameters
```r
COMP <- "Compound_A"
STUDY <- "DQCCStudy"
```

### Path Configuration
```r
CDB_LIB_PATH <- "/path/to/cdb/library"
ALSC_LIB_PATH <- "/path/to/alsc/library"
OUT_PATH <- "/path/to/output"
```

### Validation Settings
```r
LENGTH_ISSUE_NEEDED <- "Y"          # Include length mismatch checks
MAX_MISSING_PCT <- 10               # Missing value warning threshold
DUPLICATE_THRESHOLD <- 0            # Duplicate tolerance
```

---

## Utility Functions (`utils.R`)

### Data Reading
- `read_sas_dataset(path)`: Read single SAS dataset
- `read_library(lib_path)`: Read all datasets from directory

### Metadata
- `get_dataset_metadata(data, dataset_name)`: Extract variable metadata
- `get_obs_summary(dataset_list)`: Get observation counts

### Export
- `export_to_excel(data_list, file_path)`: Export to formatted Excel

### Data Quality
- `calc_missing_pct(data)`: Calculate missing percentages
- `find_duplicates(data, key_vars)`: Find duplicate records

---

## Comparison Tool Functions (`03_Compare_Tool_Functions.R`)

Extracted from the eCompare Shiny tool for reusable dataset comparison.

### Main Function

```r
result <- differing(old, new, ideal = c("key1", "key2"))
```

**Parameters**:
- `old`: Old/reference dataset
- `new`: New dataset
- `ideal`: Vector of primary key column names (optional)

**Returns**: Data frame with comparison results including:
- `Compare_status`: "New", "Modified", "Removed", or "No Change"
- `modified_info`: Which columns were modified
- Column status indicators for new/removed columns

### Wrapper Functions

```r
# Compare datasets from files
result <- compare_datasets(
  old_path = "path/to/old.sas7bdat",
  new_path = "path/to/new.sas7bdat",
  key_vars = c("USUBJID", "VISIT"),
  select_vars = c("VAR1", "VAR2", "VAR3")
)

# Export with formatting
export_comparison(result, "output.xlsx")
```

---

## Output Reports

All reports are saved to the output path specified in `config.R`.

### Report Types

1. **CDB Migration Summary** (`cdb_migration_summary_[DATE].xlsx`)
   - Dataset and variable comparison results
   - Observation count validation

2. **Data Quality Report** (`data_quality_report_[DATE].xlsx`)
   - All data quality issues by category

3. **Final Consolidated Report** (`validation_final_report_[DATE].xlsx`)
   - Executive summary with overall status
   - Aggregated statistics from all checks
   - Detailed issue listings

### Excel Features
- Multiple sheets organized by issue type
- Auto-sized columns
- Frozen header rows
- Conditional formatting (in comparison exports)

---

## Integration with QC Workflow

The Rchecks framework can be integrated with the existing QC program:

```r
# In your QC workflow script
source("Rchecks/run_all_checks.R")

# Run validation after data transfer
validation_results <- run_all_validation_checks()

# Check validation status
if (validation_results$postprocessing$validation_status == "PASSED") {
  message("Validation passed - proceeding with QC")
} else {
  warning("Validation issues found - review reports before proceeding")
}
```

---

## Requirements

### R Packages

All required packages are automatically installed when running `run_all_checks.R`:

- `haven`: Reading SAS datasets
- `openxlsx`: Excel output with formatting
- `dplyr`: Data manipulation
- `tidyr`: Data tidying
- `purrr`: Functional programming
- `readr`: Reading delimited files
- `readxl`: Reading Excel files
- `janitor`: Data cleaning
- `stringr`: String manipulation

### Installation

```r
install.packages(c("haven", "openxlsx", "dplyr", "tidyr", "purrr", 
                   "readr", "readxl", "janitor", "stringr"))
```

---

## Troubleshooting

### Path Issues

If you encounter "file not found" errors:

1. Check that paths in `config.R` are correct
2. Use forward slashes `/` or double backslashes `\\\\` in Windows paths
3. Ensure you have read permissions for data directories

### Package Issues

If package loading fails:

```r
# Force reinstall
install.packages("package_name", dependencies = TRUE)
```

### Memory Issues

For large datasets:

```r
# Increase memory limit (Windows)
memory.limit(size = 16000)

# Or process datasets in batches
```

---

## Support

For questions or issues with the validation framework, contact:

**Author**: Siriyak  
**Study**: DQCCStudy (Compound_A)

---

## Version History

- **v1.0** (2026-01-14): Initial framework creation
  - CDB migration comparison
  - Data quality checks
  - Automated reporting
  - Preprocessing and post-processing phases

---

## License

This validation framework is proprietary and for internal use only.

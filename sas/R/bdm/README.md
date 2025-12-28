# BDM (Blank Data Mapping) Generation Scripts

## Overview

This directory contains scripts for generating, validating, and managing Blank Data Mapping (BDM) specifications that document the mapping from source data to SDTM/ADaM domains.

## Scripts

### 1. generate_all_bdm.R
**Purpose**: Generate comprehensive BDM specifications for all SDTM domains

**Features**:
- Automatic variable mapping suggestions based on naming conventions
- Source variable metadata extraction (labels, types, formats, lengths)
- Sample values and missing data statistics
- Multi-sheet Excel output with mapping specification and domain summary
- Master BDM index file for all domains
- Controlled terminology placeholders

**Usage**:
```r
source("R/bdm/generate_all_bdm.R")
```

**Output**:
- `specs/bdm/BDM_DM_Demographics.xlsx`
- `specs/bdm/BDM_AE_Adverse_Events.xlsx`
- `specs/bdm/BDM_VS_Vital_Signs.xlsx`
- ... (one file per domain)
- `specs/bdm/BDM_Master_Index.xlsx` (summary of all BDMs)

### 2. create_bdm_template.R
**Purpose**: Create customizable BDM template for any domain

**Features**:
- Blank template with instructions
- Source variable metadata
- Sample values for reference
- Customizable for any source file

**Usage**:
```r
source("R/bdm/create_bdm_template.R")

# Create template for custom domain
create_bdm_template("your_file.sas7bdat", "XX", "Your Domain Description")
```

**Example**:
```r
# Create BDM template for Procedures domain
create_bdm_template("prgen.sas7bdat", "PR", "Procedures")
```

### 3. validate_bdm.R
**Purpose**: Validate BDM specifications for completeness and consistency

**Features**:
- Check for required SDTM variables
- Identify unmapped source variables
- Detect duplicate target variables
- Validate mapping logic completeness
- Generate validation report

**Usage**:
```r
source("R/bdm/validate_bdm.R")
```

**Output**: Console report showing:
- Mapping completeness percentage
- Missing required variables
- Validation issues and warnings
- Pass/Fail status for each BDM

## BDM Specification Structure

Each BDM Excel file contains multiple sheets:

### Sheet 1: Mapping_Specification
| Column | Description |
|--------|-------------|
| Row_Number | Sequential row number |
| Source_Dataset | Source SAS dataset filename |
| Source_Variable | Source variable name |
| Source_Label | Source variable label |
| Source_Type | Source data type |
| Source_Format | SAS format |
| Source_Length | Variable length |
| Target_Domain | Target SDTM/ADaM domain |
| Target_Variable | Target variable name |
| Target_Label | Target variable label |
| Target_Type | Target data type |
| Target_Length | Target variable length |
| Mapping_Logic | Mapping method (Direct, Transform, Derive, etc.) |
| Derivation_Algorithm | Detailed derivation logic |
| Controlled_Terminology | CT codelist reference |
| Codelist_Reference | CDISC CT reference |
| Required | Required variable flag |
| Core | CDISC core status (Req, Exp, Perm) |
| Comments | Additional notes |
| Sample_Values | Sample values from source |
| Missing_Count | Count of missing values |
| Missing_Percent | Percentage of missing values |

### Sheet 2: Domain_Summary
- Domain code and name
- Source file information
- Variable counts (total, mapped, unmapped)
- Generation metadata

### Sheet 3: Controlled_Terminology
- Placeholder for CT codelist mappings
- Variable-specific permitted values

## Workflow

### 1. Generate Initial BDM Specifications
```r
# Generate BDM for all domains
source("R/bdm/generate_all_bdm.R")
```

### 2. Review and Customize
- Open generated Excel files in `specs/bdm/`
- Review automatic mapping suggestions
- Fill in missing target variables
- Add derivation algorithms
- Document controlled terminology

### 3. Validate BDM Specifications
```r
# Validate all BDM files
source("R/bdm/validate_bdm.R")
```

### 4. Use BDM for Implementation
- Reference BDM specifications when writing SDTM/ADaM scripts
- Ensure all mappings are implemented as documented
- Update BDM if implementation differs from specification

## Mapping Methods

| Method | Description | Example |
|--------|-------------|---------|
| **Direct** | Direct copy from source to target | `AGE → AGE` |
| **Transform** | Apply transformation | `AEDT → AESTDTC (date format)` |
| **Derive** | Calculate from multiple variables | `BMI = WEIGHT / (HEIGHT/100)^2` |
| **Constant** | Assign constant value | `DOMAIN = "AE"` |
| **Lookup** | Use lookup table or CT | `SEX: "M" → "M", "F" → "F"` |

## Best Practices

1. **Document Everything**: Include detailed derivation algorithms for complex mappings
2. **Use Standard Terminology**: Reference CDISC CT codelists where applicable
3. **Track Changes**: Maintain version control of BDM specifications
4. **Validate Regularly**: Run validation after any BDM updates
5. **Cross-Reference**: Ensure BDM aligns with actual SDTM/ADaM implementation

## Integration with Automation Framework

BDM specifications are automatically generated during SDTM/ADaM script execution:
- Each domain script calls `generate_bdm_spec()` and `export_bdm()`
- BDM files are created in `specs/bdm/` directory
- Master automation script (`run_all.R`) can optionally run BDM generation

## Customization

To add BDM generation for additional domains:

```r
# In your custom SDTM script
bdm_spec <- generate_bdm_spec(
  source_data = your_raw_data,
  target_domain = "XX",
  mapping_list = list(
    SOURCE_VAR1 = "TARGET_VAR1",
    SOURCE_VAR2 = "TARGET_VAR2"
  )
)

export_bdm(bdm_spec, "XX")
```

## Output Location

All BDM specifications are saved to:
```
specs/bdm/
├── BDM_DM_Demographics.xlsx
├── BDM_AE_Adverse_Events.xlsx
├── BDM_VS_Vital_Signs.xlsx
├── BDM_LB_Laboratory.xlsx
├── BDM_CM_Concomitant_Medications.xlsx
├── BDM_EG_ECG_Test_Results.xlsx
├── BDM_EX_Exposure.xlsx
├── BDM_DS_Disposition.xlsx
├── BDM_MH_Medical_History.xlsx
├── BDM_SU_Substance_Use.xlsx
└── BDM_Master_Index.xlsx
```

## Support

For questions or issues with BDM generation:
1. Check the execution logs in `outputs/logs/`
2. Review the BDM validation report
3. Consult the main README.md for framework documentation

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-28

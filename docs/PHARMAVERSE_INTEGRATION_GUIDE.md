# Pharmaverse Integration Guide
## Quick Start for Phase 1 Packages

**Version**: 1.0.0  
**Last Updated**: December 29, 2025

---

## 📦 Phase 1 Packages Overview

### **Installed Packages**

| Package | Category | Purpose | Priority |
|---------|----------|---------|----------|
| **gtsummary** | TLG | Beautiful summary tables | HIGH |
| **logrx** | Utilities | Execution logging | HIGH |
| **pkglite** | eSub | Package bundling | HIGH |
| **sdtmchecks** | Validation | SDTM compliance checks | HIGH |
| **pharmaverseadam** | Synthetic | Test ADaM datasets | MEDIUM |
| **pharmaversesdtm** | Synthetic | Test SDTM datasets | MEDIUM |

---

## 🚀 Quick Start

### **1. Installation**

```r
# Run package installation
source("R/setup/00_install_packages.R")

# Packages will be installed from pharmaverse R-universe
```

### **2. Run Examples**

```r
# See all Phase 1 examples
source("R/pharmaverse_examples.R")
```

---

## 📊 **Package 1: gtsummary - Beautiful Summary Tables**

### **Why Use It?**
- Publication-ready tables with minimal code
- Automatic p-values and statistical tests
- Multiple export formats (DOCX, HTML, RTF)
- Customizable formatting

### **Basic Usage**

```r
library(gtsummary)
library(pharmaverseadam)

# Load data
adsl <- pharmaverseadam::adsl

# Create summary table
demo_table <- adsl %>%
  select(AGE, SEX, RACE, ARM) %>%
  tbl_summary(
    by = ARM,
    statistic = list(
      all_continuous() ~ "{mean} ({sd})",
      all_categorical() ~ "{n} ({p}%)"
    )
  ) %>%
  add_p() %>%
  add_overall()

# Export
demo_table %>%
  as_gt() %>%
  gt::gtsave("Table_Demographics.docx")
```

### **Integration with Framework**

Replace existing table generation in `R/tlf/tables/` with gtsummary for faster, better-looking tables.

---

## 📝 **Package 2: logrx - Execution Logging**

### **Why Use It?**
- Automatic audit trail
- Captures R session info
- Records all warnings/errors
- Regulatory compliance

### **Basic Usage**

```r
library(logrx)

# Execute script with logging
axecute(
  "R/run_all.R",
  log_name = "master_execution_log",
  log_path = "docs/logs"
)

# Log file created: docs/logs/master_execution_log.Rout
```

### **Integration with Framework**

Add to `run_all.R` to log entire execution:

```r
# At top of run_all.R
library(logrx)

# Wrap execution
axecute(
  "R/run_all_core.R",  # Rename current run_all.R
  log_name = glue("execution_log_{Sys.Date()}"),
  log_path = "docs/logs"
)
```

---

## 📦 **Package 3: pkglite - Package Bundling**

### **Why Use It?**
- Required for eSub
- Bundles R packages as text
- Regulatory submission ready
- Easy to include in eCTD

### **Basic Usage**

```r
library(pkglite)

# Bundle packages for submission
pack(
  c("admiral", "xportr", "gtsummary"),
  output = "outputs/esub/r_packages.txt"
)

# Include in eCTD submission
```

### **Integration with Framework**

Add to `R/ofs/prepare_ofs_package.R`:

```r
# Bundle all pharmaverse packages used
pkglite::pack(
  c("admiral", "xportr", "gtsummary", "logrx"),
  output = "outputs/ofs/r_packages/pharmaverse_packages.txt"
)
```

---

## ✅ **Package 4: sdtmchecks - SDTM Validation**

### **Why Use It?**
- Automated SDTM compliance checks
- Complements Pinnacle 21
- Catches common issues early
- Detailed validation reports

### **Basic Usage**

```r
library(sdtmchecks)

# Run SDTM checks
check_results <- run_all_checks(
  DM = dm,
  AE = ae,
  VS = vs
)

# View issues
print(check_results)
```

### **Integration with Framework**

Add to `R/validation/run_all_validation.R`:

```r
# After SDTM generation
cat("Running sdtmchecks validation...\n")

sdtm_check_results <- sdtmchecks::run_all_checks(
  DM = dm,
  AE = ae,
  VS = vs,
  LB = lb
)

# Save results
writexl::write_xlsx(
  sdtm_check_results,
  "outputs/validation/SDTM_Checks_Report.xlsx"
)
```

---

## 🧪 **Package 5 & 6: pharmaverseadam & pharmaversesdtm**

### **Why Use Them?**
- Realistic synthetic data
- Test framework without real data
- Training and documentation
- Consistent test cases

### **Available Datasets**

#### **pharmaverseadam**
- `adsl` - Subject-Level Analysis Dataset
- `adae` - Adverse Events Analysis
- `adlb` - Laboratory Analysis
- `advs` - Vital Signs Analysis

#### **pharmaversesdtm**
- `dm` - Demographics
- `ae` - Adverse Events
- `vs` - Vital Signs
- `lb` - Laboratory

### **Basic Usage**

```r
library(pharmaverseadam)

# Load synthetic data
test_adsl <- pharmaverseadam::adsl
test_adae <- pharmaverseadam::adae

# Use for testing
source("R/tlf/tables/table_14_1_1_demographics.R")
```

### **Integration with Framework**

Create test suite:

```r
# R/tests/test_framework.R

library(pharmaverseadam)

# Test all TLF scripts
test_adsl <- pharmaverseadam::adsl
test_adae <- pharmaverseadam::adae

# Run TLF generation
source("R/tlf/generate_all_tlf.R")

# Verify outputs
stopifnot(file.exists("outputs/tlf/tables/Table_14_1_1_Demographics.rtf"))
```

---

## 🎯 **Integration Checklist**

### **Immediate Actions**

- [x] Install Phase 1 packages
- [x] Update `00_install_packages.R`
- [x] Create integration examples
- [ ] Test with synthetic data
- [ ] Update TLF scripts to use gtsummary
- [ ] Add logrx to run_all.R
- [ ] Add pkglite to OFS preparation
- [ ] Add sdtmchecks to validation
- [ ] Create test suite with synthetic data

### **Documentation Updates**

- [ ] Update README with pharmaverse info
- [ ] Update blog post with pharmaverse section
- [ ] Create training materials
- [ ] Document best practices

---

## 📈 **Expected Benefits**

### **Time Savings**

| Task | Before | After | Improvement |
|------|--------|-------|-------------|
| **Table Creation** | 2-3 hours | 15-30 min | 75-85% |
| **Logging Setup** | 1 hour | 5 min | 90% |
| **Package Bundling** | 2 hours | 10 min | 90% |
| **SDTM Validation** | 1 day | 30 min | 95% |
| **Testing** | 2 days | 2 hours | 90% |

### **Quality Improvements**

- ✅ **Better Tables**: Publication-ready formatting
- ✅ **Complete Audit Trail**: Automatic logging
- ✅ **eSub Ready**: Proper package bundling
- ✅ **Early Detection**: SDTM issues caught sooner
- ✅ **Comprehensive Testing**: Realistic synthetic data

---

## 🔧 **Troubleshooting**

### **Installation Issues**

```r
# If packages fail to install from pharmaverse
install.packages(
  "gtsummary",
  repos = c(
    "https://pharmaverse.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

### **Common Errors**

**Error**: Package not found
**Solution**: Ensure pharmaverse R-universe is in repos

**Error**: Dependency conflicts
**Solution**: Update all packages first

```r
update.packages(ask = FALSE)
```

---

## 📚 **Resources**

- **Pharmaverse Website**: https://pharmaverse.org/
- **gtsummary**: http://www.danieldsjoberg.com/gtsummary/
- **logrx**: https://pharmaverse.github.io/logrx/
- **pkglite**: https://merck.github.io/pkglite/
- **pharmaverseadam**: https://pharmaverse.github.io/pharmaverseadam/

---

## 🚀 **Next Steps**

1. **Test Integration**: Run `pharmaverse_examples.R`
2. **Update TLF Scripts**: Integrate gtsummary
3. **Add Logging**: Integrate logrx into run_all.R
4. **Validate**: Test with synthetic data
5. **Document**: Update all documentation
6. **Train Team**: Conduct training sessions

---

**Status**: Phase 1 Complete ✅  
**Next Phase**: Phase 2 (tern, rtables, datacutr) - Planned for Q1 2026

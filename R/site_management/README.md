# Site & Subject Management - Complete Guide

## 📋 Overview

This module provides comprehensive utilities for managing study sites and generating subject IDs (USUBJID, SUBJID, screening numbers) with automated enrollment tracking.

---

## 📁 Module Structure

```
R/site_management/
├── site_management.R          # Site registry and management
├── subject_id_generation.R    # Subject ID generation
└── README.md                  # This file
```

---

## 🏥 Site Management

### **Initialize Site Registry**

```r
source("R/site_management/site_management.R")

# Create site registry
initialize_site_registry()
```

**Creates**: `docs/Site_Registry.xlsx`

### **Add Sites**

```r
# Add US site
add_site(
  site_name = "Memorial Hospital",
  country = "USA",
  principal_investigator = "Dr. John Smith",
  pi_email = "jsmith@memorial.org",
  city = "New York",
  state = "NY",
  target_enrollment = 30
)
# Result: Site Number = USA-001

# Add UK site
add_site(
  site_name = "London Medical Center",
  country = "GBR",
  principal_investigator = "Dr. Jane Doe",
  city = "London",
  target_enrollment = 25
)
# Result: Site Number = GBR-001
```

### **Site Number Formats**

| Format | Example | Description |
|--------|---------|-------------|
| `"CCC-NNN"` | USA-001 | Country code - Sequential (default) |
| `"CCNNN"` | USA001 | No separator |
| `"NNN"` | 001 | Sequential only |
| `"RRRNNN"` | NAM001 | Region code + Sequential |

### **View Site Registry**

```r
# View all sites
view_site_registry()

# View active sites only
view_site_registry(status = "Active")

# View sites by country
view_site_registry(country = "USA")
```

### **Update Site Status**

```r
# Activate site
update_site_status("USA-001", "Active")

# Close site
update_site_status("USA-002", "Closed", comments = "Low enrollment")
```

### **Generate Site Report**

```r
generate_site_summary_report()
```

**Output**: `outputs/Site_Summary_Report.xlsx`

---

## 👤 Subject ID Generation

### **Initialize Subject Registry**

```r
source("R/site_management/subject_id_generation.R")

# Create subject registry
initialize_subject_registry()
```

**Creates**: `docs/Subject_Registry.xlsx`

### **Enroll Subject**

```r
# Enroll subject at site USA-001
enroll_subject(
  site_number = "USA-001",
  study_id = "STUDY-001"
)
```

**Generates**:
- USUBJID: `STUDY-001-USA-001-0001`
- SUBJID: `USA-001-0001`
- Screening Number: `SCR-USA-001-0001`

### **ID Format Options**

#### **SUBJID Formats**

| Format | Example | Description |
|--------|---------|-------------|
| `"SSSS-NNNN"` | USA-001-0001 | Site - Sequential (default) |
| `"SSSSNNNN"` | USA0010001 | No separator |
| `"NNNN"` | 0001 | Sequential only |

#### **USUBJID Formats**

| Format | Example | Description |
|--------|---------|-------------|
| `"STUDY-SUBJID"` | STUDY-001-USA-001-0001 | Study - SUBJID (default) |
| `"STUDYSUBJID"` | STUDY001USA0010001 | No separator |
| `"SUBJID"` | USA-001-0001 | SUBJID only |

#### **Screening Number Formats**

| Format | Example | Description |
|--------|---------|-------------|
| `"SCR-SSSS-NNNN"` | SCR-USA-001-0001 | SCR - Site - Sequential (default) |
| `"SCRSSSSNNNN"` | SCRUSA0010001 | All concatenated |
| `"SSSS-SCR-NNNN"` | USA-001-SCR-0001 | Site - SCR - Sequential |

### **Randomize Subject**

```r
randomize_subject(
  usubjid = "STUDY-001-USA-001-0001",
  treatment_assignment = "Treatment A"
)
```

**Generates**:
- Randomization Number: `RAND-0001`
- Updates status to "Randomized"

### **Update Subject Status**

```r
# Complete subject
update_subject_status(
  usubjid = "STUDY-001-USA-001-0001",
  status = "Completed"
)

# Discontinue subject
update_subject_status(
  usubjid = "STUDY-001-USA-001-0002",
  status = "Discontinued",
  discontinuation_reason = "Adverse Event",
  comments = "Subject withdrew consent"
)
```

### **Subject Status Values**

- `"Screening"` - Subject enrolled, not yet randomized
- `"Randomized"` - Subject randomized to treatment
- `"Completed"` - Subject completed study
- `"Discontinued"` - Subject discontinued early

### **View Subject Registry**

```r
# View all subjects
view_subject_registry()

# View subjects at specific site
view_subject_registry(site_number = "USA-001")

# View randomized subjects only
view_subject_registry(status = "Randomized")
```

### **Generate Enrollment Report**

```r
generate_enrollment_report()
```

**Output**: `outputs/Enrollment_Report.xlsx`

**Includes**:
- Overall enrollment summary
- Enrollment by site
- Enrollment by status
- Enrollment timeline
- Subject details

---

## 📊 Complete Workflow Example

### **Study Setup**

```r
# 1. Load utilities
source("R/site_management/site_management.R")
source("R/site_management/subject_id_generation.R")

# 2. Initialize registries
initialize_site_registry()
initialize_subject_registry()

# 3. Add sites
add_site(
  site_name = "Memorial Hospital",
  country = "USA",
  principal_investigator = "Dr. John Smith",
  city = "New York",
  target_enrollment = 30
)

add_site(
  site_name = "London Medical Center",
  country = "GBR",
  principal_investigator = "Dr. Jane Doe",
  city = "London",
  target_enrollment = 25
)

add_site(
  site_name = "Tokyo General Hospital",
  country = "JPN",
  principal_investigator = "Dr. Yuki Tanaka",
  city = "Tokyo",
  target_enrollment = 20
)
```

### **Subject Enrollment**

```r
# Enroll subjects at USA-001
for (i in 1:5) {
  enroll_subject(site_number = "USA-001", study_id = "STUDY-001")
}

# Enroll subjects at GBR-001
for (i in 1:3) {
  enroll_subject(site_number = "GBR-001", study_id = "STUDY-001")
}

# Enroll subjects at JPN-001
for (i in 1:4) {
  enroll_subject(site_number = "JPN-001", study_id = "STUDY-001")
}
```

### **Randomization**

```r
# Randomize subjects
randomize_subject("STUDY-001-USA-001-0001", "Treatment A")
randomize_subject("STUDY-001-USA-001-0002", "Placebo")
randomize_subject("STUDY-001-USA-001-0003", "Treatment A")
randomize_subject("STUDY-001-GBR-001-0001", "Placebo")
randomize_subject("STUDY-001-GBR-001-0002", "Treatment A")
```

### **Status Updates**

```r
# Complete subjects
update_subject_status("STUDY-001-USA-001-0001", "Completed")
update_subject_status("STUDY-001-USA-001-0002", "Completed")

# Discontinue subject
update_subject_status(
  "STUDY-001-USA-001-0003",
  "Discontinued",
  discontinuation_reason = "Lost to follow-up"
)
```

### **Generate Reports**

```r
# Site summary
generate_site_summary_report()

# Enrollment summary
generate_enrollment_report()

# View current status
view_site_registry()
view_subject_registry()
```

---

## 📋 Registry Files

### **Site Registry** (`docs/Site_Registry.xlsx`)

| Column | Description |
|--------|-------------|
| Site_Number | Unique site identifier |
| Site_Name | Hospital/clinic name |
| Site_Country | Country code (ISO 3166) |
| Principal_Investigator | PI name |
| Site_Status | Active/Inactive/Closed |
| Target_Enrollment | Planned enrollment |
| Actual_Enrollment | Current enrollment |

### **Subject Registry** (`docs/Subject_Registry.xlsx`)

| Column | Description |
|--------|-------------|
| USUBJID | Unique subject identifier |
| SUBJID | Site-specific subject ID |
| Site_Number | Site identifier |
| Screening_Number | Screening number |
| Randomization_Number | Randomization number |
| Subject_Status | Current status |
| Treatment_Assignment | Assigned treatment |

---

## 🎯 Best Practices

### **Site Management**
1. ✅ Initialize registry before adding sites
2. ✅ Use consistent country codes (ISO 3166)
3. ✅ Set realistic target enrollment
4. ✅ Update site status regularly
5. ✅ Track enrollment vs. target

### **Subject ID Generation**
1. ✅ Use consistent ID formats across study
2. ✅ Generate IDs sequentially
3. ✅ Never reuse subject IDs
4. ✅ Maintain complete audit trail
5. ✅ Update status promptly

### **Enrollment Tracking**
1. ✅ Enroll subjects immediately upon consent
2. ✅ Randomize only eligible subjects
3. ✅ Document discontinuation reasons
4. ✅ Generate regular enrollment reports
5. ✅ Monitor enrollment vs. target

---

## 📊 Reports Generated

### **Site Summary Report**
- Overall site statistics
- Enrollment by country
- Site status breakdown
- Enrollment rates

### **Enrollment Report**
- Total enrollment
- Enrollment by site
- Enrollment by status
- Enrollment timeline
- Randomization rate

---

## 🔧 Customization

### **Custom Site Number Format**

```r
# Use custom format
add_site(
  site_name = "Hospital Name",
  country = "USA",
  principal_investigator = "Dr. Name",
  format = "CCNNN"  # USA001 instead of USA-001
)
```

### **Custom Subject ID Format**

```r
# Use custom formats
enroll_subject(
  site_number = "USA-001",
  study_id = "ABC",
  subjid_format = "SSSSNNNN",      # USA0010001
  usubjid_format = "STUDYSUBJID",  # ABCUSA0010001
  screening_format = "SCRSSSSNNNN" # SCRUSA0010001
)
```

---

## 📞 Integration with Main Framework

### **Use in SDTM Generation**

```r
# Load subject registry
subject_registry <- readxl::read_excel("docs/Subject_Registry.xlsx")

# Merge with raw data
dm_data <- raw_dm %>%
  left_join(
    subject_registry %>% select(SUBJID, USUBJID, Site_Number),
    by = "SUBJID"
  )
```

### **Use in Randomization**

```r
# Load randomization list
randomization_list <- readxl::read_excel("docs/Subject_Registry.xlsx") %>%
  filter(Subject_Status == "Randomized") %>%
  select(USUBJID, Treatment_Assignment, Randomization_Number)
```

---

## 🎯 Summary

### **Site Management Features**
✅ Site registry with full details  
✅ Automated site number generation  
✅ Enrollment tracking by site  
✅ Site status management  
✅ Comprehensive site reports  

### **Subject ID Features**
✅ USUBJID generation  
✅ SUBJID generation  
✅ Screening number generation  
✅ Randomization number generation  
✅ Subject status tracking  
✅ Enrollment reports  

### **Total Functions**: 15+

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-28

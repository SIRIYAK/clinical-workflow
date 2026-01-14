# Blinding Module - Quick Reference

## 📁 Module Structure

```
R/blinding/
├── blinding_utilities.R       # Core functions
├── emergency_unblinding.R     # Emergency procedures
├── planned_unblinding.R       # Interim & final unblinding
└── README.md                  # This file
```

---

## 🚀 Quick Start

### **Initialize Blinding System**

```r
# Load utilities
source("R/blinding/blinding_utilities.R")

# Initialize blinding log
initialize_blinding_log()
```

---

## 🔒 Core Functions

### **1. Mask Treatment Assignments**

```r
# Mask treatments for blinded analysis
adsl_blinded <- mask_treatment_assignments(adsl, blinded = TRUE)

# Result:
# Treatment A → Treatment 1
# Treatment B → Treatment 2
# Placebo → Treatment 3
```

### **2. Check Blinding Status**

```r
# Check if data is blinded
check_blinding_status(adsl)
```

### **3. Unmask Treatment Assignments**

```r
# Unmask after final analysis
adsl_unmasked <- unmask_treatment_assignments(adsl_blinded)
```

### **4. View Blinding Log**

```r
# View all events
view_blinding_log()

# View specific event type
view_blinding_log(event_type = "Emergency Unblinding")
```

### **5. Generate Integrity Report**

```r
# Assess blinding integrity
generate_blinding_integrity_report(adsl)
```

---

## 🚨 Emergency Unblinding

### **Request Emergency Unblinding**

```r
source("R/blinding/emergency_unblinding.R")

emergency_unblinding(
  subject_id = "SUBJ-0123",
  site_number = "001",
  reason = "Serious adverse event requiring knowledge of treatment",
  requested_by = "Dr. John Smith, Principal Investigator"
)
```

**What it does**:
- ✅ Generates emergency unblinding form (DOCX)
- ✅ Logs event in blinding log
- ✅ Provides checklist of next steps
- ✅ Creates documentation trail

---

## 📅 Planned Unblinding

### **Interim Analysis**

```r
source("R/blinding/planned_unblinding.R")

interim_analysis_unblinding(
  analysis_number = 1,
  data_cutoff_date = "2024-06-30",
  unblinded_statistician = "Dr. Jane Doe"
)
```

**What it does**:
- ✅ Logs interim analysis unblinding
- ✅ Provides responsibilities checklist
- ✅ Maintains blinding for study team
- ✅ Enables DMC review

### **Final Analysis**

```r
final_analysis_unblinding(
  database_lock_date = "2024-12-15",
  locked_by = "Data Management Team"
)
```

**What it does**:
- ✅ Confirms database lock
- ✅ Logs final unblinding
- ✅ Provides unmasking instructions
- ✅ Guides through next steps

### **Unmask All Datasets**

```r
unmask_all_datasets()
```

**What it does**:
- ✅ Unma sks all ADaM datasets
- ✅ Saves unmasked versions
- ✅ Prepares for TLF generation

---

## 📊 Complete Workflow

### **Blinded Analysis Workflow**

```r
# 1. Initialize
source("R/blinding/blinding_utilities.R")
initialize_blinding_log()

# 2. Mask treatments
adsl <- haven::read_sas("data/adam/adsl.sas7bdat")
adsl_blinded <- mask_treatment_assignments(adsl, blinded = TRUE)

# 3. Run blinded analyses
source("R/biostat/advanced_models/advanced_statistical_models.R")

# 4. Generate blinded TLF
source("R/tlf/generate_all_tlf.R")

# 5. Check integrity
generate_blinding_integrity_report(adsl_blinded)
```

### **Unblinding Workflow**

```r
# 1. Lock database
# (Done by Data Management)

# 2. Final unblinding
source("R/blinding/planned_unblinding.R")
final_analysis_unblinding(
  database_lock_date = "2024-12-15",
  locked_by = "DM Team"
)

# 3. Unmask datasets
unmask_all_datasets()

# 4. Generate unblinded TLF
source("R/tlf/generate_all_tlf.R")

# 5. Create CSR
source("R/documents/generate_csr_document.R")
```

---

## 📋 Blinding Log

### **Log Structure**

| Field | Description |
|-------|-------------|
| Log_ID | Unique identifier |
| Date | Event date |
| Time | Event time |
| Event_Type | Emergency/Interim/Final |
| Subject_ID | Subject or "All subjects" |
| Requested_By | Person requesting |
| Reason | Justification |
| Approved_By | Approver name |
| Treatment_Revealed | What was revealed |
| Documentation | Supporting docs |
| Comments | Additional notes |

### **Event Types**

- **Emergency Unblinding** - Subject-level emergency
- **Planned Unblinding - Interim Analysis** - DMC review
- **Planned Unblinding - Final Analysis** - Study completion

---

## 🔍 Blinding Integrity

### **Acceptable Thresholds**

| Status | Unblinding Rate | Action |
|--------|-----------------|--------|
| **Excellent** | 0% | None |
| **Acceptable** | <5% | Monitor |
| **Concerning** | ≥5% | Investigate |

### **Monitoring**

```r
# Regular integrity checks
generate_blinding_integrity_report(adsl)

# Review log
view_blinding_log()
```

---

## 📄 Generated Files

### **Blinding Log**
- `docs/Blinding_Unblinding_Log.xlsx`

### **Emergency Forms**
- `docs/Emergency_Unblinding_Form_SUBJ-XXXX_YYYYMMDD.docx`

### **Reports**
- `outputs/Blinding_Integrity_Report.xlsx`

---

## ⚠️ Important Notes

### **Before Unblinding**
1. ✅ Confirm database is locked
2. ✅ Verify all data queries resolved
3. ✅ Obtain sponsor approval
4. ✅ Document in blinding log

### **During Blinded Period**
1. ✅ Use masked treatment labels
2. ✅ Maintain separate blinded/unblinded teams
3. ✅ Secure randomization code
4. ✅ Log all unblinding events

### **After Unblinding**
1. ✅ Unmask all datasets
2. ✅ Regenerate TLF with actual labels
3. ✅ Update CSR with unmasked results
4. ✅ Archive blinded versions

---

## 🎯 Best Practices

1. **Initialize early** - Set up blinding log at study start
2. **Document everything** - Log all unblinding events
3. **Maintain separation** - Keep blinded/unblinded teams separate
4. **Check integrity** - Regular monitoring of unblinding rate
5. **Secure access** - Restrict access to randomization code
6. **Verify before unblinding** - Always confirm database lock

---

## 📞 Support

For questions about blinding procedures:
- Review: `docs/BLINDING_UNBLINDING_GUIDE.md`
- Contact: Medical Monitor or Study Statistician

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-28

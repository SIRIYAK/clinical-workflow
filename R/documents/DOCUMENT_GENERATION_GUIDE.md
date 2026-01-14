# Automated Document Generation Guide

## 📄 Overview

This module provides **automated document generation** for clinical trial reports in **DOCX, RTF, and LaTeX** formats. Documents include embedded TLF outputs and placeholder text for manual editing by statisticians.

---

## 🎯 Key Features

✅ **Automated Structure** - ICH E3 compliant sections  
✅ **Embedded TLF** - Tables, listings, and figures automatically included  
✅ **Placeholder Text** - Clear markers for manual editing  
✅ **Multiple Formats** - DOCX, RTF, LaTeX support  
✅ **90% Automated** - Minimal manual work required  

---

## 📁 Available Generators

### **1. Clinical Study Report (CSR) Generator**

**Script**: `R/documents/generate_csr_document.R`

**Generates**:
- DOCX version (editable in Microsoft Word)
- RTF version (universal format)
- LaTeX version (for PDF compilation)

**Sections Included**:
- 14.1 Demographics and Baseline Characteristics
- 14.2 Efficacy Results
- 14.3 Safety Results
- 14.4 Figures
- 15. Conclusions

**Usage**:
```r
source("R/documents/generate_csr_document.R")
```

**Output**:
- `outputs/documents/CSR_STUDY-001_YYYY-MM-DD.docx`
- `outputs/documents/CSR_STUDY-001_YYYY-MM-DD.rtf`
- `outputs/documents/CSR_STUDY-001_YYYY-MM-DD.tex`

---

### **2. Statistical Analysis Plan (SAP) Generator**

**Script**: `R/documents/generate_sap_document.R`

**Generates**:
- DOCX version with structured sections

**Sections Included**:
- 1. Study Overview
- 2. Sample Size and Power
- 3. Analysis Populations
- 4. Endpoints
- 5. Statistical Methods
- 6. Tables, Listings, and Figures
- 7. Changes from Protocol
- Appendix A: Mock Table Shells

**Usage**:
```r
source("R/documents/generate_sap_document.R")
```

**Output**:
- `outputs/documents/SAP_STUDY-001_v1.0_YYYY-MM-DD.docx`

---

## 🔧 How It Works

### **Step 1: TLF Generation**

First, generate all TLF outputs:

```r
source("R/tlf/generate_all_tlf.R")
```

This creates:
- Tables in `outputs/tlf/tables/`
- Listings in `outputs/tlf/listings/`
- Figures in `outputs/tlf/figures/`

### **Step 2: Document Generation**

Run document generators:

```r
# Generate CSR
source("R/documents/generate_csr_document.R")

# Generate SAP
source("R/documents/generate_sap_document.R")
```

### **Step 3: Manual Editing**

1. Open generated DOCX file in Microsoft Word
2. Search for `[PLACEHOLDER]` text
3. Replace with study-specific content
4. Review embedded tables and figures
5. Finalize document

---

## 📝 Placeholder System

### **Placeholder Format**

All manual edits are marked with:
```
[PLACEHOLDER: Description of what to add]
```

### **Example Placeholders**

```
Demographics Section:
[PLACEHOLDER: Add narrative description of demographic characteristics]

Mean age: [ADD MEAN AGE] years
Sex distribution: [ADD PERCENTAGE] male, [ADD PERCENTAGE] female

Efficacy Section:
Treatment difference: [ADD DIFFERENCE] (95% CI: [ADD CI])
P-value: [ADD P-VALUE]

Safety Section:
Any adverse event: [ADD PERCENTAGE]% in treatment group
```

### **Finding Placeholders**

In Microsoft Word:
1. Press `Ctrl+F` (Find)
2. Search for: `[PLACEHOLDER`
3. Navigate through all placeholders
4. Replace with actual values

---

## 🖼️ TLF Embedding

### **How TLF is Embedded**

#### **DOCX Format**
- **Tables**: Referenced with file path (RTF tables)
- **Figures**: Directly embedded as images

```r
# Figure embedding example
body_add_img(src = "outputs/tlf/figures/Figure_14_4_KM_Survival.png", 
             width = 6, height = 4)
```

#### **RTF Format**
- **Tables**: Placeholders with file references
- **Figures**: Not embedded (reference only)

#### **LaTeX Format**
- **Tables**: Referenced with file path
- **Figures**: Embedded via `\includegraphics`

```latex
\begin{figure}[h]
\centering
\includegraphics[width=0.8\textwidth]{../../outputs/tlf/figures/Figure_14_4_KM_Survival.png}
\caption{Kaplan-Meier Survival Curves}
\end{figure}
```

---

## 📊 Document Structure

### **CSR Structure (ICH E3 Compliant)**

```
CLINICAL STUDY REPORT
├── Title Page
├── 14. Clinical Study Report Body
│   ├── 14.1 Demographics and Baseline Characteristics
│   │   ├── Narrative text (with placeholders)
│   │   └── Table 14.1.1 (embedded/referenced)
│   ├── 14.2 Efficacy Results
│   │   ├── 14.2.1 Primary Endpoint
│   │   │   ├── Narrative text (with placeholders)
│   │   │   └── Table 14.2.1 (embedded/referenced)
│   │   └── 14.2.2 Secondary Endpoints
│   ├── 14.3 Safety Results
│   │   ├── 14.3.1 Adverse Events
│   │   │   ├── Narrative text (with placeholders)
│   │   │   └── Table 14.3.1 (embedded/referenced)
│   │   └── 14.3.2 Laboratory Results
│   ├── 14.4 Figures
│   │   ├── Figure 14.4: Kaplan-Meier (embedded)
│   │   ├── Figure 14.5: Forest Plot (embedded)
│   │   └── Figure 14.6: Waterfall Plot (embedded)
│   └── 15. Conclusions
│       └── Overall conclusions (with placeholders)
```

### **SAP Structure**

```
STATISTICAL ANALYSIS PLAN
├── Title Page
├── 1. Study Overview
│   ├── Study objectives
│   └── Study design
├── 2. Sample Size and Power
│   └── Sample size table (embedded)
├── 3. Analysis Populations
│   └── Population definitions table (embedded)
├── 4. Endpoints
│   ├── Primary endpoint
│   ├── Secondary endpoints
│   └── Safety endpoints
├── 5. Statistical Methods
│   ├── Primary analysis
│   ├── Secondary analyses
│   ├── Missing data handling
│   ├── Multiplicity adjustment
│   ├── Subgroup analyses
│   └── Interim analyses
├── 6. Tables, Listings, and Figures
│   └── TLF shell table (embedded)
├── 7. Changes from Protocol
└── Appendix A: Mock Table Shells
```

---

## 🎨 Customization

### **Modify Study Information**

Edit configuration in script:

```r
STUDY_CONFIG <- list(
  study_id = "YOUR-STUDY-ID",
  protocol = "YOUR-PROTOCOL",
  sponsor = "Your Company",
  indication = "Your Indication",
  phase = "Phase III"
)
```

### **Add Custom Sections**

```r
# Add new section
doc <- doc %>%
  body_add_par("14.5 Custom Analysis", style = "heading 2") %>%
  body_add_par("[PLACEHOLDER: Add custom analysis description]", style = "Normal")
```

### **Embed Additional TLF**

```r
# Embed additional figure
figure_file <- "outputs/tlf/figures/Figure_14_7_Custom.png"
if (file.exists(figure_file)) {
  doc <- doc %>%
    body_add_img(src = figure_file, width = 6, height = 4)
}
```

---

## 📋 Workflow

### **Complete Document Generation Workflow**

```
1. Generate SDTM/ADaM datasets
   ↓
2. Run statistical analyses
   ↓
3. Generate TLF outputs
   ↓
4. Run document generators  ← YOU ARE HERE
   ↓
5. Manual editing (fill placeholders)
   ↓
6. Internal review
   ↓
7. Finalize for submission
```

### **Typical Timeline**

| Step | Time Required |
|------|---------------|
| TLF Generation | 10-15 minutes (automated) |
| Document Generation | 2-3 minutes (automated) |
| Manual Editing | 2-4 hours (statistician) |
| Review & Finalization | 1-2 days |

---

## 💡 Best Practices

### **Before Generation**
1. ✅ Ensure all TLF outputs are generated
2. ✅ Review TLF outputs for accuracy
3. ✅ Update study configuration

### **During Manual Editing**
1. ✅ Work systematically through placeholders
2. ✅ Cross-reference with analysis results
3. ✅ Maintain consistent terminology
4. ✅ Add study-specific context

### **After Editing**
1. ✅ Remove all `[PLACEHOLDER]` markers
2. ✅ Verify all tables/figures are correct
3. ✅ Check formatting consistency
4. ✅ Independent review

---

## 🔍 Quality Checks

### **Automated Checks**

The generator automatically:
- ✅ Checks if TLF files exist
- ✅ Embeds available figures
- ✅ References table files
- ✅ Creates document index

### **Manual Checks Required**

Statistician should verify:
- ✅ All placeholders filled
- ✅ Numbers match analysis results
- ✅ Tables/figures correctly referenced
- ✅ Narrative text accurate
- ✅ Conclusions supported by data

---

## 📦 Output Files

### **Generated Files**

| File | Format | Purpose |
|------|--------|---------|
| `CSR_*.docx` | DOCX | Editable in Word |
| `CSR_*.rtf` | RTF | Universal format |
| `CSR_*.tex` | LaTeX | PDF compilation |
| `SAP_*.docx` | DOCX | Editable SAP |
| `Document_Index.xlsx` | Excel | File index |

### **File Locations**

```
outputs/documents/
├── CSR_STUDY-001_2024-12-28.docx
├── CSR_STUDY-001_2024-12-28.rtf
├── CSR_STUDY-001_2024-12-28.tex
├── SAP_STUDY-001_v1.0_2024-12-28.docx
└── Document_Index.xlsx
```

---

## 🚀 Advanced Features

### **LaTeX to PDF Compilation**

```bash
# Compile LaTeX to PDF
cd outputs/documents
pdflatex CSR_STUDY-001_2024-12-28.tex
pdflatex CSR_STUDY-001_2024-12-28.tex  # Run twice for references
```

### **Batch Document Generation**

```r
# Generate all documents at once
source("R/documents/generate_csr_document.R")
source("R/documents/generate_sap_document.R")
```

---

## 📊 Summary

### **What's Automated**

✅ **90% of document structure**  
✅ **TLF embedding**  
✅ **Section organization**  
✅ **Formatting**  
✅ **Placeholder insertion**  

### **What Requires Manual Work**

❌ **~10% narrative text** (study-specific)  
❌ **Interpretation of results**  
❌ **Clinical context**  
❌ **Conclusions**  

### **Time Savings**

- **Traditional**: 2-3 days to create CSR from scratch
- **With Automation**: 2-4 hours to fill placeholders
- **Savings**: ~80-90% time reduction

---

## 🎯 Next Steps

1. **Generate TLF outputs** first
2. **Run document generators**
3. **Open DOCX files** in Word
4. **Fill placeholders** systematically
5. **Review and finalize**

---

**This automated document generation saves significant time while maintaining quality and compliance!** 📄✅

---

**Version**: 1.0.0  
**Last Updated**: 2025-12-28

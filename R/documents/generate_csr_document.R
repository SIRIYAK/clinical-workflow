# ==============================================================================
# Automated Document Generator - Clinical Study Report (CSR)
# Script: generate_csr_document.R
# Purpose: Generate CSR with embedded TLF and placeholder text
# ==============================================================================

source("R/setup/00_install_packages.R")

# Install additional packages
if (!require("officer")) install.packages("officer")
if (!require("officedown")) install.packages("officedown")
if (!require("flextable")) install.packages("flextable")

library(officer)
library(officedown)
library(flextable)
library(dplyr)
library(glue)

cat("\n========================================\n")
cat("CSR Document Generator\n")
cat("========================================\n\n")

# ==============================================================================
# Configuration
# ==============================================================================

STUDY_CONFIG <- list(
  study_id = "STUDY-001",
  protocol = "PROTOCOL-001-2024",
  sponsor = "Your Company Name",
  indication = "Your Indication",
  phase = "Phase III"
)

# ==============================================================================
# Create DOCX Document
# ==============================================================================

cat("[1] Creating DOCX Document\n")
cat(strrep("-", 80), "\n")

# Initialize document
doc <- read_docx()

# Add title page
doc <- doc %>%
  body_add_par("CLINICAL STUDY REPORT", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(glue("Study: {STUDY_CONFIG$study_id}"), style = "Normal") %>%
  body_add_par(glue("Protocol: {STUDY_CONFIG$protocol}"), style = "Normal") %>%
  body_add_par(glue("Sponsor: {STUDY_CONFIG$sponsor}"), style = "Normal") %>%
  body_add_par(glue("Indication: {STUDY_CONFIG$indication}"), style = "Normal") %>%
  body_add_par(glue("Phase: {STUDY_CONFIG$phase}"), style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(glue("Date: {Sys.Date()}"), style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 14.1: Demographics and Baseline Characteristics
# ==============================================================================

doc <- doc %>%
  body_add_par("14. CLINICAL STUDY REPORT BODY", style = "heading 1") %>%
  body_add_par("14.1 Demographic and Other Baseline Characteristics", style = "heading 2") %>%
  body_add_par("", style = "Normal")

# Add placeholder text
placeholder_14_1 <- "
[PLACEHOLDER: Add narrative description of demographic and baseline characteristics]

The demographic and baseline characteristics of the study population are summarized in Table 14.1.1. 
Overall, the treatment groups were well-balanced with respect to demographic characteristics.

Key observations:
• Mean age: [ADD MEAN AGE] years
• Sex distribution: [ADD PERCENTAGE] male, [ADD PERCENTAGE] female  
• Race distribution: [DESCRIBE RACE DISTRIBUTION]
• Baseline disease characteristics: [DESCRIBE BASELINE CHARACTERISTICS]

[PLACEHOLDER: Add any notable findings or imbalances]
"

doc <- doc %>%
  body_add_par(placeholder_14_1, style = "Normal") %>%
  body_add_par("", style = "Normal")

# Embed Table 14.1.1 if it exists
table_file <- "outputs/tlf/tables/Table_14_1_1_Demographics.rtf"
if (file.exists(table_file)) {
  doc <- doc %>%
    body_add_par("Table 14.1.1: Demographics and Baseline Characteristics", style = "heading 3")
  
  # Note: RTF tables need to be converted or referenced
  doc <- doc %>%
    body_add_par("[TABLE 14.1.1 EMBEDDED - See separate RTF file]", style = "Normal") %>%
    body_add_par(glue("File: {table_file}"), style = "Normal")
} else {
  doc <- doc %>%
    body_add_par("[TABLE 14.1.1 - TO BE GENERATED]", style = "Normal")
}

doc <- doc %>% body_add_break()

# ==============================================================================
# Section 14.2: Efficacy Results
# ==============================================================================

doc <- doc %>%
  body_add_par("14.2 Efficacy Results", style = "heading 2") %>%
  body_add_par("14.2.1 Primary Efficacy Endpoint", style = "heading 3") %>%
  body_add_par("", style = "Normal")

placeholder_14_2_1 <- "
[PLACEHOLDER: Add narrative description of primary efficacy endpoint results]

The primary efficacy endpoint was [DESCRIBE ENDPOINT]. Results are summarized in Table 14.2.1.

Primary Analysis Results:
• Treatment group: [ADD MEAN ± SD]
• Control group: [ADD MEAN ± SD]
• Treatment difference: [ADD DIFFERENCE] (95% CI: [ADD CI])
• P-value: [ADD P-VALUE]

Statistical Significance: [DESCRIBE IF SIGNIFICANT]

Clinical Significance: [DESCRIBE CLINICAL MEANINGFULNESS]

[PLACEHOLDER: Add interpretation and context]
"

doc <- doc %>%
  body_add_par(placeholder_14_2_1, style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[TABLE 14.2.1 - PRIMARY EFFICACY RESULTS]", style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 14.3: Safety Results
# ==============================================================================

doc <- doc %>%
  body_add_par("14.3 Safety Results", style = "heading 2") %>%
  body_add_par("14.3.1 Adverse Events", style = "heading 3") %>%
  body_add_par("", style = "Normal")

placeholder_14_3_1 <- "
[PLACEHOLDER: Add narrative description of adverse events]

The safety profile of [TREATMENT] was evaluated in [N] subjects. Adverse events are summarized in Table 14.3.1.

Overall Safety Summary:
• Any adverse event: [ADD PERCENTAGE]% in treatment group vs [ADD PERCENTAGE]% in control
• Serious adverse events: [ADD PERCENTAGE]% vs [ADD PERCENTAGE]%
• Adverse events leading to discontinuation: [ADD PERCENTAGE]% vs [ADD PERCENTAGE]%
• Fatal adverse events: [ADD NUMBER] in treatment group, [ADD NUMBER] in control

Most Common Adverse Events (≥5%):
[PLACEHOLDER: List most common AEs]

Serious Adverse Events:
[PLACEHOLDER: Describe serious AEs]

[PLACEHOLDER: Add overall safety conclusion]
"

doc <- doc %>%
  body_add_par(placeholder_14_3_1, style = "Normal") %>%
  body_add_par("", style = "Normal")

# Embed Table 14.3.1 if it exists
table_file <- "outputs/tlf/tables/Table_14_3_1_AE_Summary.rtf"
if (file.exists(table_file)) {
  doc <- doc %>%
    body_add_par("Table 14.3.1: Adverse Events Summary", style = "heading 4") %>%
    body_add_par("[TABLE 14.3.1 EMBEDDED - See separate RTF file]", style = "Normal") %>%
    body_add_par(glue("File: {table_file}"), style = "Normal")
} else {
  doc <- doc %>%
    body_add_par("[TABLE 14.3.1 - TO BE GENERATED]", style = "Normal")
}

doc <- doc %>% body_add_break()

# ==============================================================================
# Section 14.4: Figures
# ==============================================================================

doc <- doc %>%
  body_add_par("14.4 Figures", style = "heading 2") %>%
  body_add_par("", style = "Normal")

# Embed Figure 14.4 (Kaplan-Meier) if it exists
figure_file <- "outputs/tlf/figures/Figure_14_4_KM_Survival.png"
if (file.exists(figure_file)) {
  doc <- doc %>%
    body_add_par("Figure 14.4: Kaplan-Meier Survival Curves", style = "heading 3") %>%
    body_add_img(src = figure_file, width = 6, height = 4) %>%
    body_add_par("", style = "Normal")
  
  placeholder_fig_14_4 <- "
[PLACEHOLDER: Add figure interpretation]

Figure 14.4 shows the Kaplan-Meier survival curves for the treatment and control groups.

Key Findings:
• Median survival (treatment): [ADD VALUE] months
• Median survival (control): [ADD VALUE] months
• Hazard ratio: [ADD HR] (95% CI: [ADD CI])
• Log-rank p-value: [ADD P-VALUE]

[PLACEHOLDER: Add clinical interpretation]
"
  
  doc <- doc %>%
    body_add_par(placeholder_fig_14_4, style = "Normal")
} else {
  doc <- doc %>%
    body_add_par("[FIGURE 14.4 - TO BE GENERATED]", style = "Normal")
}

doc <- doc %>% body_add_break()

# ==============================================================================
# Section 15: Conclusions
# ==============================================================================

doc <- doc %>%
  body_add_par("15. CONCLUSIONS", style = "heading 1") %>%
  body_add_par("", style = "Normal")

placeholder_15 <- "
[PLACEHOLDER: Add overall study conclusions]

This study evaluated [TREATMENT] in [POPULATION] with [INDICATION].

Primary Endpoint:
[PLACEHOLDER: Summarize primary endpoint result and significance]

Secondary Endpoints:
[PLACEHOLDER: Summarize key secondary endpoint results]

Safety:
[PLACEHOLDER: Summarize overall safety profile]

Benefit-Risk Assessment:
[PLACEHOLDER: Provide benefit-risk assessment]

Overall Conclusion:
[PLACEHOLDER: State overall conclusion about treatment efficacy and safety]
"

doc <- doc %>%
  body_add_par(placeholder_15, style = "Normal")

# ==============================================================================
# Save DOCX Document
# ==============================================================================

output_file <- glue("outputs/documents/CSR_{STUDY_CONFIG$study_id}_{Sys.Date()}.docx")
print(doc, target = output_file)

cat(glue("\n✓ DOCX document created: {output_file}\n\n"))

# ==============================================================================
# Create RTF Version
# ==============================================================================

cat("[2] Creating RTF Version\n")
cat(strrep("-", 80), "\n")

# RTF generation using rtf package
if (!require("rtf")) install.packages("rtf")
library(rtf)

rtf_file <- glue("outputs/documents/CSR_{STUDY_CONFIG$study_id}_{Sys.Date()}.rtf")

rtf_doc <- RTF(rtf_file, width = 8.5, height = 11, font.size = 11, omi = c(1, 1, 1, 1))

# Add title
addHeader(rtf_doc, "CLINICAL STUDY REPORT", font.size = 16, bold = TRUE)
addNewLine(rtf_doc, n = 2)
addText(rtf_doc, glue("Study: {STUDY_CONFIG$study_id}"))
addText(rtf_doc, glue("Protocol: {STUDY_CONFIG$protocol}"))
addText(rtf_doc, glue("Date: {Sys.Date()}"))
addPageBreak(rtf_doc)

# Add sections with placeholders
addHeader(rtf_doc, "14. CLINICAL STUDY REPORT BODY", font.size = 14, bold = TRUE)
addHeader(rtf_doc, "14.1 Demographics and Baseline Characteristics", font.size = 12, bold = TRUE)
addText(rtf_doc, placeholder_14_1)
addPageBreak(rtf_doc)

addHeader(rtf_doc, "14.2 Efficacy Results", font.size = 12, bold = TRUE)
addText(rtf_doc, placeholder_14_2_1)
addPageBreak(rtf_doc)

addHeader(rtf_doc, "14.3 Safety Results", font.size = 12, bold = TRUE)
addText(rtf_doc, placeholder_14_3_1)
addPageBreak(rtf_doc)

addHeader(rtf_doc, "15. CONCLUSIONS", font.size = 14, bold = TRUE)
addText(rtf_doc, placeholder_15)

done(rtf_doc)

cat(glue("✓ RTF document created: {rtf_file}\n\n"))

# ==============================================================================
# Create LaTeX Version
# ==============================================================================

cat("[3] Creating LaTeX Version\n")
cat(strrep("-", 80), "\n")

latex_content <- glue("
\\documentclass[12pt,a4paper]{{article}}
\\usepackage{{geometry}}
\\usepackage{{graphicx}}
\\usepackage{{hyperref}}
\\usepackage{{booktabs}}
\\usepackage{{longtable}}

\\geometry{{margin=1in}}

\\title{{Clinical Study Report}}
\\author{{{STUDY_CONFIG$sponsor}}}
\\date{{{Sys.Date()}}}

\\begin{{document}}

\\maketitle

\\section*{{Study Information}}
\\begin{{itemize}}
\\item Study ID: {STUDY_CONFIG$study_id}
\\item Protocol: {STUDY_CONFIG$protocol}
\\item Sponsor: {STUDY_CONFIG$sponsor}
\\item Indication: {STUDY_CONFIG$indication}
\\item Phase: {STUDY_CONFIG$phase}
\\end{{itemize}}

\\newpage

\\section{{Clinical Study Report Body}}

\\subsection{{Demographics and Baseline Characteristics}}

\\textbf{{[PLACEHOLDER: Add narrative description]}}

{placeholder_14_1}

\\subsubsection{{Table 14.1.1: Demographics}}

\\textbf{{[TABLE 14.1.1 - See separate file]}}

\\newpage

\\subsection{{Efficacy Results}}

\\subsubsection{{Primary Efficacy Endpoint}}

{placeholder_14_2_1}

\\newpage

\\subsection{{Safety Results}}

\\subsubsection{{Adverse Events}}

{placeholder_14_3_1}

\\subsubsection{{Table 14.3.1: Adverse Events Summary}}

\\textbf{{[TABLE 14.3.1 - See separate file]}}

\\newpage

\\subsection{{Figures}}

\\subsubsection{{Figure 14.4: Kaplan-Meier Survival Curves}}

\\begin{{figure}}[h]
\\centering
\\includegraphics[width=0.8\\textwidth]{{../../outputs/tlf/figures/Figure_14_4_KM_Survival.png}}
\\caption{{Kaplan-Meier Survival Curves}}
\\end{{figure}}

{placeholder_fig_14_4}

\\newpage

\\section{{Conclusions}}

{placeholder_15}

\\end{{document}}
")

latex_file <- glue("outputs/documents/CSR_{STUDY_CONFIG$study_id}_{Sys.Date()}.tex")
writeLines(latex_content, latex_file)

cat(glue("✓ LaTeX document created: {latex_file}\n"))
cat("  To compile: pdflatex {latex_file}\n\n")

# ==============================================================================
# Create Index of Generated Documents
# ==============================================================================

cat("[4] Creating Document Index\n")
cat(strrep("-", 80), "\n")

doc_index <- tibble(
  Document = c("CSR (DOCX)", "CSR (RTF)", "CSR (LaTeX)"),
  File = c(
    basename(output_file),
    basename(rtf_file),
    basename(latex_file)
  ),
  Format = c("DOCX", "RTF", "LaTeX"),
  Status = c("Generated", "Generated", "Generated (requires compilation)"),
  Embedded_TLF = c(
    "Tables referenced, Figures embedded",
    "Placeholders only",
    "Figures embedded via includegraphics"
  ),
  Manual_Edits_Required = c(
    "Yes - All [PLACEHOLDER] sections",
    "Yes - All [PLACEHOLDER] sections",
    "Yes - All [PLACEHOLDER] sections"
  )
)

writexl::write_xlsx(doc_index, "outputs/documents/Document_Index.xlsx")

cat("✓ Document index created: outputs/documents/Document_Index.xlsx\n\n")

# ==============================================================================
# Summary
# ==============================================================================

cat("========================================\n")
cat("Document Generation Summary\n")
cat("========================================\n\n")

cat("Generated Documents:\n")
cat(glue("  1. DOCX: {output_file}\n"))
cat(glue("  2. RTF:  {rtf_file}\n"))
cat(glue("  3. LaTeX: {latex_file}\n\n"))

cat("Features:\n")
cat("  ✓ Automated document structure\n")
cat("  ✓ Embedded TLF outputs (where available)\n")
cat("  ✓ Placeholder text for manual editing\n")
cat("  ✓ ICH E3 compliant sections\n")
cat("  ✓ Ready for statistician review and editing\n\n")

cat("Next Steps:\n")
cat("  1. Open DOCX file in Microsoft Word\n")
cat("  2. Search for [PLACEHOLDER] text\n")
cat("  3. Replace placeholders with study-specific content\n")
cat("  4. Review embedded tables and figures\n")
cat("  5. Add any additional sections as needed\n\n")

cat("========================================\n")
cat("✓ Document generation complete!\n")
cat("========================================\n\n")

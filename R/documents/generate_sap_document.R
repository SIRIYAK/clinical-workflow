# ==============================================================================
# Automated Document Generator - Statistical Analysis Plan (SAP)
# Script: generate_sap_document.R
# Purpose: Generate SAP with embedded tables and placeholder text
# ==============================================================================

source("R/setup/00_install_packages.R")

library(officer)
library(flextable)
library(dplyr)
library(glue)

cat("\n========================================\n")
cat("SAP Document Generator\n")
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
# Create DOCX SAP
# ==============================================================================

cat("[1] Creating SAP Document\n")
cat(strrep("-", 80), "\n")

doc <- read_docx()

# Title Page
doc <- doc %>%
  body_add_par("STATISTICAL ANALYSIS PLAN", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(glue("Study: {STUDY_CONFIG$study_id}"), style = "Normal") %>%
  body_add_par(glue("Protocol: {STUDY_CONFIG$protocol}"), style = "Normal") %>%
  body_add_par(glue("Sponsor: {STUDY_CONFIG$sponsor}"), style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par(glue("SAP Version: 1.0"), style = "Normal") %>%
  body_add_par(glue("Date: {Sys.Date()}"), style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 1: Study Overview
# ==============================================================================

doc <- doc %>%
  body_add_par("1. STUDY OVERVIEW", style = "heading 1") %>%
  body_add_par("", style = "Normal")

placeholder_1 <- "
[PLACEHOLDER: Add study overview]

1.1 Study Objectives

Primary Objective:
[PLACEHOLDER: State primary objective]

Secondary Objectives:
[PLACEHOLDER: List secondary objectives]

1.2 Study Design

This is a [PLACEHOLDER: randomized/non-randomized], [PLACEHOLDER: blinded/open-label], 
[PLACEHOLDER: parallel-group/crossover] study evaluating [PLACEHOLDER: treatment] in 
[PLACEHOLDER: population].

Treatment Groups:
• Group 1: [PLACEHOLDER: Treatment description]
• Group 2: [PLACEHOLDER: Control description]

Study Duration: [PLACEHOLDER: Duration]
"

doc <- doc %>%
  body_add_par(placeholder_1, style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 2: Sample Size and Power
# ==============================================================================

doc <- doc %>%
  body_add_par("2. SAMPLE SIZE AND POWER", style = "heading 1") %>%
  body_add_par("", style = "Normal")

# Create sample size table
sample_size_table <- tibble(
  Parameter = c("Effect Size", "Alpha (two-sided)", "Power", "Sample Size per Group", "Total Sample Size", "Dropout Rate", "Adjusted Sample Size"),
  Value = c(
    "[ENTER EFFECT SIZE]",
    "0.05",
    "0.80",
    "[CALCULATED N]",
    "[CALCULATED TOTAL]",
    "[ENTER DROPOUT %]",
    "[ADJUSTED N]"
  )
)

ft <- flextable(sample_size_table) %>%
  theme_booktabs() %>%
  autofit()

doc <- doc %>%
  body_add_par("2.1 Sample Size Calculation", style = "heading 2") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[PLACEHOLDER: Describe sample size rationale]", style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_flextable(ft) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[PLACEHOLDER: Add assumptions and justification]", style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 3: Analysis Populations
# ==============================================================================

doc <- doc %>%
  body_add_par("3. ANALYSIS POPULATIONS", style = "heading 1") %>%
  body_add_par("", style = "Normal")

populations_table <- tibble(
  Population = c("Intent-to-Treat (ITT)", "Per-Protocol (PP)", "Safety"),
  Definition = c(
    "All randomized subjects",
    "ITT subjects without major protocol deviations",
    "All subjects who received at least one dose"
  ),
  Primary_Analysis = c("Yes", "Sensitivity", "No"),
  Safety_Analysis = c("No", "No", "Yes")
)

ft_pop <- flextable(populations_table) %>%
  theme_booktabs() %>%
  autofit()

doc <- doc %>%
  body_add_flextable(ft_pop) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[PLACEHOLDER: Add additional population definitions if needed]", style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 4: Endpoints
# ==============================================================================

doc <- doc %>%
  body_add_par("4. ENDPOINTS", style = "heading 1") %>%
  body_add_par("", style = "Normal")

placeholder_4 <- "
4.1 Primary Endpoint

[PLACEHOLDER: Define primary endpoint]

Endpoint: [PLACEHOLDER: Endpoint description]
Measurement: [PLACEHOLDER: How measured]
Timing: [PLACEHOLDER: When measured]

4.2 Secondary Endpoints

[PLACEHOLDER: List and define secondary endpoints]

1. [PLACEHOLDER: Secondary endpoint 1]
2. [PLACEHOLDER: Secondary endpoint 2]
3. [PLACEHOLDER: Secondary endpoint 3]

4.3 Safety Endpoints

[PLACEHOLDER: Define safety endpoints]

• Adverse events
• Laboratory parameters
• Vital signs
• [PLACEHOLDER: Other safety measures]
"

doc <- doc %>%
  body_add_par(placeholder_4, style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 5: Statistical Methods
# ==============================================================================

doc <- doc %>%
  body_add_par("5. STATISTICAL METHODS", style = "heading 1") %>%
  body_add_par("", style = "Normal")

placeholder_5 <- "
5.1 Primary Analysis

Analysis Method: [PLACEHOLDER: e.g., MMRM, ANCOVA, etc.]

Model Specification:
[PLACEHOLDER: Specify statistical model]

Example: CHG ~ TRT + VISIT + TRT*VISIT + BASE + (1|USUBJID)

Covariates:
[PLACEHOLDER: List covariates]

Significance Level: α = 0.05 (two-sided)

5.2 Secondary Analyses

[PLACEHOLDER: Describe methods for each secondary endpoint]

5.3 Handling of Missing Data

Primary Approach: [PLACEHOLDER: e.g., MMRM assumes MAR]

Sensitivity Analyses:
1. Complete case analysis
2. Last observation carried forward (LOCF)
3. Multiple imputation
4. [PLACEHOLDER: Other sensitivity analyses]

5.4 Multiplicity Adjustment

Method: [PLACEHOLDER: e.g., Hochberg, Bonferroni, etc.]

[PLACEHOLDER: Describe testing hierarchy if applicable]

5.5 Subgroup Analyses

Subgroups (Exploratory):
• Age: <65 years, ≥65 years
• Sex: Male, Female
• [PLACEHOLDER: Other subgroups]

Method: Forest plots with interaction tests

5.6 Interim Analyses

[PLACEHOLDER: Describe interim analysis plan if applicable]

Timing: [PLACEHOLDER: When]
Purpose: [PLACEHOLDER: Efficacy/Futility/Safety]
Alpha Spending: [PLACEHOLDER: Method]
"

doc <- doc %>%
  body_add_par(placeholder_5, style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 6: Tables, Listings, and Figures
# ==============================================================================

doc <- doc %>%
  body_add_par("6. TABLES, LISTINGS, AND FIGURES", style = "heading 1") %>%
  body_add_par("", style = "Normal")

# Create TLF shell table
tlf_shells <- tibble(
  Output_ID = c("T-14.1.1", "T-14.1.2", "T-14.2.1", "T-14.3.1", "L-16.2.1", "F-14.4"),
  Type = c("Table", "Table", "Table", "Table", "Listing", "Figure"),
  Title = c(
    "Demographics and Baseline Characteristics",
    "Subject Disposition",
    "Efficacy Results - Primary Endpoint",
    "Adverse Events Summary",
    "Adverse Events Listing",
    "Kaplan-Meier Survival Curves"
  ),
  Population = c("Safety", "All", "ITT", "Safety", "Safety", "ITT")
)

ft_tlf <- flextable(tlf_shells) %>%
  theme_booktabs() %>%
  autofit()

doc <- doc %>%
  body_add_par("6.1 Planned Tables, Listings, and Figures", style = "heading 2") %>%
  body_add_par("", style = "Normal") %>%
  body_add_flextable(ft_tlf) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[PLACEHOLDER: Add mock table shells in appendix]", style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Section 7: Changes from Protocol
# ==============================================================================

doc <- doc %>%
  body_add_par("7. CHANGES FROM PROTOCOL", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[PLACEHOLDER: Document any changes from protocol and justifications]", style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("None at this time.", style = "Normal") %>%
  body_add_break()

# ==============================================================================
# Appendix: Mock Tables
# ==============================================================================

doc <- doc %>%
  body_add_par("APPENDIX A: MOCK TABLE SHELLS", style = "heading 1") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("[PLACEHOLDER: Include mock table shells showing structure and layout]", style = "Normal")

# ==============================================================================
# Save SAP Document
# ==============================================================================

output_file <- glue("outputs/documents/SAP_{STUDY_CONFIG$study_id}_v1.0_{Sys.Date()}.docx")
print(doc, target = output_file)

cat(glue("\n✓ SAP document created: {output_file}\n\n"))

cat("========================================\n")
cat("SAP Generation Complete\n")
cat("========================================\n\n")

cat("Next Steps:\n")
cat("  1. Open DOCX file in Microsoft Word\n")
cat("  2. Fill in all [PLACEHOLDER] sections\n")
cat("  3. Update sample size calculations\n")
cat("  4. Add mock table shells\n")
cat("  5. Review and finalize before database lock\n\n")

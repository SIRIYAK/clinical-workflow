# ==============================================================================
# Table 14.2.1: Vital Signs Summary
# Script: table_vital_signs.R
# Purpose: Generate vital signs summary statistics table
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.2.1: Vital Signs\n")
cat("========================================\n\n")

# Read ADVS
advs <- haven::read_sas(file.path(PATHS$adam, "advs.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y")

# ==============================================================================
# Baseline Summary
# ==============================================================================

cat("Calculating baseline summaries...\n")

baseline_summary <- advs %>%
  filter(ABLFL == "Y") %>%
  group_by(TRT01P, PARAMCD, PARAM) %>%
  summarise(
    N = sum(!is.na(BASE)),
    Mean = mean(BASE, na.rm = TRUE),
    SD = sd(BASE, na.rm = TRUE),
    Median = median(BASE, na.rm = TRUE),
    Min = min(BASE, na.rm = TRUE),
    Max = max(BASE, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Visit = "Baseline",
    `Mean (SD)` = sprintf("%.1f (%.2f)", Mean, SD),
    `Median (Min, Max)` = sprintf("%.1f (%.1f, %.1f)", Median, Min, Max)
  ) %>%
  select(TRT01P, PARAM, Visit, N, `Mean (SD)`, `Median (Min, Max)`)

# ==============================================================================
# Post-Baseline Summary
# ==============================================================================

cat("Calculating post-baseline summaries...\n")

postbl_summary <- advs %>%
  filter(ANL01FL == "Y") %>%
  group_by(TRT01P, PARAMCD, PARAM) %>%
  summarise(
    N = sum(!is.na(AVAL)),
    Mean = mean(AVAL, na.rm = TRUE),
    SD = sd(AVAL, na.rm = TRUE),
    Median = median(AVAL, na.rm = TRUE),
    Min = min(AVAL, na.rm = TRUE),
    Max = max(AVAL, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Visit = "End of Treatment",
    `Mean (SD)` = sprintf("%.1f (%.2f)", Mean, SD),
    `Median (Min, Max)` = sprintf("%.1f (%.1f, %.1f)", Median, Min, Max)
  ) %>%
  select(TRT01P, PARAM, Visit, N, `Mean (SD)`, `Median (Min, Max)`)

# ==============================================================================
# Change from Baseline
# ==============================================================================

cat("Calculating change from baseline...\n")

chg_summary <- advs %>%
  filter(ANL01FL == "Y", !is.na(CHG)) %>%
  group_by(TRT01P, PARAMCD, PARAM) %>%
  summarise(
    N = sum(!is.na(CHG)),
    Mean = mean(CHG, na.rm = TRUE),
    SD = sd(CHG, na.rm = TRUE),
    Median = median(CHG, na.rm = TRUE),
    Min = min(CHG, na.rm = TRUE),
    Max = max(CHG, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Visit = "Change from Baseline",
    `Mean (SD)` = sprintf("%.1f (%.2f)", Mean, SD),
    `Median (Min, Max)` = sprintf("%.1f (%.1f, %.1f)", Median, Min, Max)
  ) %>%
  select(TRT01P, PARAM, Visit, N, `Mean (SD)`, `Median (Min, Max)`)

# ==============================================================================
# Combine All
# ==============================================================================

vs_summary_long <- bind_rows(
  baseline_summary,
  postbl_summary,
  chg_summary
)

# Pivot to wide
vs_summary_wide <- vs_summary_long %>%
  pivot_wider(
    id_cols = c(PARAM, Visit),
    names_from = TRT01P,
    values_from = c(N, `Mean (SD)`, `Median (Min, Max)`),
    values_fill = ""
  )

# ==============================================================================
# Create Table
# ==============================================================================

title <- "Table 14.2.1\nVital Signs Summary Statistics\nSafety Population"

footnotes <- c(
  "SD = Standard Deviation",
  "Change from baseline = Post-baseline value - Baseline value",
  glue("Generated: {Sys.Date()}")
)

vs_table_ft <- create_regulatory_table(vs_summary_wide, title, footnotes)

# ==============================================================================
# Export
# ==============================================================================

export_table_rtf(vs_table_ft, "Table_14_2_1_Vital_Signs")
export_table_docx(vs_table_ft, "Table_14_2_1_Vital_Signs")

cat("\n✓ Table 14.2.1 generation complete!\n\n")

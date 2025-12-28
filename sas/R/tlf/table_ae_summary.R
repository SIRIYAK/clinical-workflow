# ==============================================================================
# Table 14.3.1: Adverse Events Summary
# Script: table_ae_summary.R
# Purpose: Generate AE summary table by treatment group
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.3.1: AE Summary\n")
cat("========================================\n\n")

# Read ADAE and ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y")

adae <- haven::read_sas(file.path(PATHS$adam, "adae.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", TRTEMFL == "Y")  # Treatment-emergent AEs only

cat(glue("Safety Population: {nrow(adsl)} subjects\n"))
cat(glue("Treatment-Emergent AEs: {nrow(adae)} events\n\n"))

# ==============================================================================
# Calculate AE Summaries
# ==============================================================================

cat("Calculating AE summaries...\n")

# Subjects with at least one AE
ae_any <- adae %>%
  group_by(TRT01P) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(
    adsl %>% count(TRT01P, name = "N"),
    by = "TRT01P"
  ) %>%
  mutate(
    Category = "Subjects with at least one AE",
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, n_subj/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Subjects with serious AEs
ae_serious <- adae %>%
  filter(AESER == "Y") %>%
  group_by(TRT01P) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(
    adsl %>% count(TRT01P, name = "N"),
    by = "TRT01P"
  ) %>%
  mutate(
    Category = "Subjects with at least one serious AE",
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, n_subj/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Subjects with severe AEs
ae_severe <- adae %>%
  filter(AESEV == "SEVERE") %>%
  group_by(TRT01P) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(
    adsl %>% count(TRT01P, name = "N"),
    by = "TRT01P"
  ) %>%
  mutate(
    Category = "Subjects with at least one severe AE",
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, n_subj/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Subjects with related AEs
ae_related <- adae %>%
  filter(AREL == "RELATED") %>%
  group_by(TRT01P) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(
    adsl %>% count(TRT01P, name = "N"),
    by = "TRT01P"
  ) %>%
  mutate(
    Category = "Subjects with at least one related AE",
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, n_subj/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Subjects with AEs leading to discontinuation
ae_disc <- adae %>%
  filter(AEACN == "DRUG WITHDRAWN") %>%
  group_by(TRT01P) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(
    adsl %>% count(TRT01P, name = "N"),
    by = "TRT01P"
  ) %>%
  mutate(
    Category = "Subjects with AEs leading to discontinuation",
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, n_subj/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Subjects with fatal AEs
ae_fatal <- adae %>%
  filter(AEOUT == "FATAL") %>%
  group_by(TRT01P) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(
    adsl %>% count(TRT01P, name = "N"),
    by = "TRT01P"
  ) %>%
  mutate(
    Category = "Subjects with fatal AEs",
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, n_subj/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# ==============================================================================
# Combine Summaries
# ==============================================================================

cat("Combining summaries...\n")

ae_summary_long <- bind_rows(
  ae_any,
  ae_serious,
  ae_severe,
  ae_related,
  ae_disc,
  ae_fatal
)

# Pivot to wide format
ae_summary_wide <- ae_summary_long %>%
  pivot_wider(
    id_cols = Category,
    names_from = TRT01P,
    values_from = `n (%)`,
    values_fill = "0 (0.0%)"
  )

# ==============================================================================
# Create Formatted Table
# ==============================================================================

cat("Creating formatted table...\n")

title <- "Table 14.3.1\nSummary of Adverse Events\nSafety Population"

footnotes <- c(
  "AE = Adverse Event",
  "Treatment-emergent AEs are defined as events with onset date on or after first dose of study drug",
  glue("Population: Safety population (N={nrow(adsl)})"),
  glue("Generated: {Sys.Date()}")
)

ae_summary_ft <- create_regulatory_table(
  data = ae_summary_wide,
  title = title,
  footnotes = footnotes
)

# ==============================================================================
# Export Table
# ==============================================================================

cat("Exporting table...\n")

export_table_rtf(ae_summary_ft, "Table_14_3_1_AE_Summary")
export_table_docx(ae_summary_ft, "Table_14_3_1_AE_Summary")

cat("\n========================================\n")
cat("✓ Table 14.3.1 generation complete!\n")
cat("========================================\n\n")

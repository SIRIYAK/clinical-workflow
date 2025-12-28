# ==============================================================================
# Table 14.3.2: Adverse Events by System Organ Class and Preferred Term
# Script: table_ae_by_soc.R
# Purpose: Generate AE table by SOC and PT
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.3.2: AE by SOC and PT\n")
cat("========================================\n\n")

# Read data
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y")

adae <- haven::read_sas(file.path(PATHS$adam, "adae.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", TRTEMFL == "Y")

# Get N per treatment
n_per_trt <- adsl %>% count(TRT01P, name = "N")

# ==============================================================================
# Calculate AE Frequencies by SOC and PT
# ==============================================================================

cat("Calculating AE frequencies...\n")

ae_freq <- adae %>%
  group_by(TRT01P, AEBODSYS, AEDECOD) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  left_join(n_per_trt, by = "TRT01P") %>%
  mutate(
    pct = n_subj / N * 100,
    `n (%)` = sprintf("%d (%.1f%%)", n_subj, pct)
  ) %>%
  select(TRT01P, AEBODSYS, AEDECOD, `n (%)`)

# Pivot to wide
ae_freq_wide <- ae_freq %>%
  pivot_wider(
    id_cols = c(AEBODSYS, AEDECOD),
    names_from = TRT01P,
    values_from = `n (%)`,
    values_fill = "0 (0.0%)"
  ) %>%
  arrange(AEBODSYS, AEDECOD) %>%
  mutate(
    `Preferred Term` = paste0("  ", AEDECOD)
  ) %>%
  select(`System Organ Class` = AEBODSYS, `Preferred Term`, everything(), -AEDECOD)

# Add SOC headers
soc_list <- unique(ae_freq_wide$`System Organ Class`)
final_table <- tibble()

for (soc in soc_list) {
  # SOC header row
  soc_row <- ae_freq_wide %>%
    filter(`System Organ Class` == soc) %>%
    slice(1) %>%
    mutate(
      `System Organ Class` = soc,
      `Preferred Term` = ""
    ) %>%
    select(`System Organ Class`, `Preferred Term`)
  
  # PT rows
  pt_rows <- ae_freq_wide %>%
    filter(`System Organ Class` == soc) %>%
    mutate(`System Organ Class` = "")
  
  final_table <- bind_rows(final_table, soc_row, pt_rows)
}

# ==============================================================================
# Create Table
# ==============================================================================

title <- "Table 14.3.2\nAdverse Events by System Organ Class and Preferred Term\nSafety Population"

footnotes <- c(
  "AE = Adverse Event; PT = Preferred Term; SOC = System Organ Class",
  "Treatment-emergent AEs only",
  "Subjects counted once per PT within each SOC",
  glue("Population: Safety population (N={nrow(adsl)})"),
  glue("Generated: {Sys.Date()}")
)

ae_soc_ft <- create_regulatory_table(final_table, title, footnotes)

# ==============================================================================
# Export
# ==============================================================================

export_table_rtf(ae_soc_ft, "Table_14_3_2_AE_by_SOC_PT")
export_table_docx(ae_soc_ft, "Table_14_3_2_AE_by_SOC_PT")

cat("\n✓ Table 14.3.2 generation complete!\n\n")

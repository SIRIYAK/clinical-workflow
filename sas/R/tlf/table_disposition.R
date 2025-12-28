# ==============================================================================
# Table 14.1.2: Subject Disposition
# Script: table_disposition.R
# Purpose: Generate subject disposition summary table
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.1.2: Disposition\n")
cat("========================================\n\n")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble()

cat(glue("Total Subjects: {nrow(adsl)}\n\n"))

# ==============================================================================
# Disposition Categories
# ==============================================================================

cat("Calculating disposition categories...\n")

# Screened
screened <- adsl %>%
  count(TRT01P) %>%
  mutate(
    Category = "Screened",
    `n (%)` = sprintf("%d", n)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Randomized
randomized <- adsl %>%
  filter(ITTFL == "Y") %>%
  count(TRT01P) %>%
  left_join(adsl %>% count(TRT01P, name = "N"), by = "TRT01P") %>%
  mutate(
    Category = "Randomized",
    `n (%)` = sprintf("%d (%.1f%%)", n, n/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Treated (Safety Population)
treated <- adsl %>%
  filter(SAFFL == "Y") %>%
  count(TRT01P) %>%
  left_join(adsl %>% count(TRT01P, name = "N"), by = "TRT01P") %>%
  mutate(
    Category = "Treated",
    `n (%)` = sprintf("%d (%.1f%%)", n, n/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Completed
completed <- adsl %>%
  filter(DCSREAS == "COMPLETED") %>%
  count(TRT01P) %>%
  left_join(adsl %>% count(TRT01P, name = "N"), by = "TRT01P") %>%
  mutate(
    Category = "Completed",
    `n (%)` = sprintf("%d (%.1f%%)", n, n/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Discontinued
discontinued <- adsl %>%
  filter(DCSREAS != "COMPLETED") %>%
  count(TRT01P) %>%
  left_join(adsl %>% count(TRT01P, name = "N"), by = "TRT01P") %>%
  mutate(
    Category = "Discontinued",
    `n (%)` = sprintf("%d (%.1f%%)", n, n/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# Discontinuation reasons
disc_reasons <- adsl %>%
  filter(DCSREAS != "COMPLETED") %>%
  count(TRT01P, DCSREAS) %>%
  left_join(adsl %>% count(TRT01P, name = "N"), by = "TRT01P") %>%
  mutate(
    Category = paste0("  ", DCSREAS),
    `n (%)` = sprintf("%d (%.1f%%)", n, n/N*100)
  ) %>%
  select(TRT01P, Category, `n (%)`)

# ==============================================================================
# Combine All
# ==============================================================================

disp_table_long <- bind_rows(
  screened,
  randomized,
  treated,
  completed,
  discontinued,
  disc_reasons
)

# Pivot to wide
disp_table_wide <- disp_table_long %>%
  pivot_wider(
    id_cols = Category,
    names_from = TRT01P,
    values_from = `n (%)`,
    values_fill = "0 (0.0%)"
  )

# ==============================================================================
# Create Table
# ==============================================================================

title <- "Table 14.1.2\nSubject Disposition\nAll Subjects"

footnotes <- c(
  glue("Total subjects: N={nrow(adsl)}"),
  glue("Generated: {Sys.Date()}")
)

disp_table_ft <- create_regulatory_table(disp_table_wide, title, footnotes)

# ==============================================================================
# Export
# ==============================================================================

export_table_rtf(disp_table_ft, "Table_14_1_2_Disposition")
export_table_docx(disp_table_ft, "Table_14_1_2_Disposition")

cat("\n✓ Table 14.1.2 generation complete!\n\n")

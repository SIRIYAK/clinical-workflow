# ==============================================================================
# Table 14.1.1: Demographic and Baseline Characteristics
# Script: table_demographics.R
# Purpose: Generate ICH E3 Section 14.1 demographic table
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.1.1: Demographics\n")
cat("========================================\n\n")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y")  # Safety population

cat(glue("Safety Population: {nrow(adsl)} subjects\n\n"))

# ==============================================================================
# Age Statistics
# ==============================================================================

cat("Calculating age statistics...\n")

age_summary <- adsl %>%
  group_by(TRT01P) %>%
  summarise(
    N = sum(!is.na(AGE)),
    Mean = mean(AGE, na.rm = TRUE),
    SD = sd(AGE, na.rm = TRUE),
    Median = median(AGE, na.rm = TRUE),
    Min = min(AGE, na.rm = TRUE),
    Max = max(AGE, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Statistic = "Age (years)",
    `n` = as.character(N),
    `Mean (SD)` = sprintf("%.1f (%.2f)", Mean, SD),
    `Median` = sprintf("%.1f", Median),
    `Min, Max` = sprintf("%.0f, %.0f", Min, Max)
  ) %>%
  select(TRT01P, Statistic, n, `Mean (SD)`, Median, `Min, Max`)

# ==============================================================================
# Age Categories
# ==============================================================================

cat("Calculating age categories...\n")

age_cat_summary <- adsl %>%
  count(TRT01P, AGEGR1) %>%
  group_by(TRT01P) %>%
  mutate(
    Total = sum(n),
    Percent = n / Total * 100,
    Statistic = paste0("  ", AGEGR1),
    `n` = as.character(n),
    `Mean (SD)` = sprintf("%d (%.1f%%)", n, Percent),
    Median = "",
    `Min, Max` = ""
  ) %>%
  select(TRT01P, Statistic, n, `Mean (SD)`, Median, `Min, Max`)

# ==============================================================================
# Sex
# ==============================================================================

cat("Calculating sex distribution...\n")

sex_summary <- adsl %>%
  count(TRT01P, SEX) %>%
  group_by(TRT01P) %>%
  mutate(
    Total = sum(n),
    Percent = n / Total * 100,
    Statistic = paste0("  ", SEX),
    `n` = as.character(n),
    `Mean (SD)` = sprintf("%d (%.1f%%)", n, Percent),
    Median = "",
    `Min, Max` = ""
  ) %>%
  select(TRT01P, Statistic, n, `Mean (SD)`, Median, `Min, Max`)

# Add header row
sex_header <- tibble(
  TRT01P = unique(adsl$TRT01P)[1],
  Statistic = "Sex, n (%)",
  `n` = "",
  `Mean (SD)` = "",
  Median = "",
  `Min, Max` = ""
)

sex_summary <- bind_rows(sex_header, sex_summary)

# ==============================================================================
# Race
# ==============================================================================

cat("Calculating race distribution...\n")

race_summary <- adsl %>%
  count(TRT01P, RACE) %>%
  group_by(TRT01P) %>%
  mutate(
    Total = sum(n),
    Percent = n / Total * 100,
    Statistic = paste0("  ", RACE),
    `n` = as.character(n),
    `Mean (SD)` = sprintf("%d (%.1f%%)", n, Percent),
    Median = "",
    `Min, Max` = ""
  ) %>%
  select(TRT01P, Statistic, n, `Mean (SD)`, Median, `Min, Max`)

# Add header row
race_header <- tibble(
  TRT01P = unique(adsl$TRT01P)[1],
  Statistic = "Race, n (%)",
  `n` = "",
  `Mean (SD)` = "",
  Median = "",
  `Min, Max` = ""
)

race_summary <- bind_rows(race_header, race_summary)

# ==============================================================================
# Ethnicity
# ==============================================================================

cat("Calculating ethnicity distribution...\n")

ethnic_summary <- adsl %>%
  count(TRT01P, ETHNIC) %>%
  group_by(TRT01P) %>%
  mutate(
    Total = sum(n),
    Percent = n / Total * 100,
    Statistic = paste0("  ", ETHNIC),
    `n` = as.character(n),
    `Mean (SD)` = sprintf("%d (%.1f%%)", n, Percent),
    Median = "",
    `Min, Max` = ""
  ) %>%
  select(TRT01P, Statistic, n, `Mean (SD)`, Median, `Min, Max`)

# Add header row
ethnic_header <- tibble(
  TRT01P = unique(adsl$TRT01P)[1],
  Statistic = "Ethnicity, n (%)",
  `n` = "",
  `Mean (SD)` = "",
  Median = "",
  `Min, Max` = ""
)

ethnic_summary <- bind_rows(ethnic_header, ethnic_summary)

# ==============================================================================
# Combine All Summaries
# ==============================================================================

cat("Combining all summaries...\n")

demo_table_long <- bind_rows(
  age_summary,
  age_cat_summary,
  sex_summary,
  race_summary,
  ethnic_summary
)

# Pivot to wide format
demo_table_wide <- demo_table_long %>%
  pivot_wider(
    id_cols = Statistic,
    names_from = TRT01P,
    values_from = c(n, `Mean (SD)`, Median, `Min, Max`),
    values_fill = ""
  )

# Reorder columns
treatment_groups <- unique(adsl$TRT01P)
col_order <- c("Statistic")
for (trt in treatment_groups) {
  col_order <- c(col_order, 
                 paste0("n_", trt),
                 paste0("Mean (SD)_", trt),
                 paste0("Median_", trt),
                 paste0("Min, Max_", trt))
}

demo_table_wide <- demo_table_wide %>%
  select(any_of(col_order))

# Clean column names
names(demo_table_wide) <- gsub("_.*", "", names(demo_table_wide))
names(demo_table_wide)[1] <- "Characteristic"

# ==============================================================================
# Create Formatted Table
# ==============================================================================

cat("Creating formatted table...\n")

title <- "Table 14.1.1\nDemographic and Baseline Characteristics\nSafety Population"

footnotes <- c(
  "SD = Standard Deviation",
  glue("Population: Safety population (N={nrow(adsl)})"),
  glue("Generated: {Sys.Date()}")
)

demo_table_ft <- create_regulatory_table(
  data = demo_table_wide,
  title = title,
  footnotes = footnotes
)

# ==============================================================================
# Export Table
# ==============================================================================

cat("Exporting table...\n")

export_table_rtf(demo_table_ft, "Table_14_1_1_Demographics")
export_table_docx(demo_table_ft, "Table_14_1_1_Demographics")

cat("\n========================================\n")
cat("✓ Table 14.1.1 generation complete!\n")
cat("========================================\n\n")

# ==============================================================================
# Table 14.3.5: Laboratory Shift Tables
# Script: table_lab_shift.R
# Purpose: Generate laboratory shift from baseline tables
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.3.5: Lab Shift Tables\n")
cat("========================================\n\n")

# Read ADLB
adlb <- haven::read_sas(file.path(PATHS$adam, "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", ANL01FL == "Y", !is.na(BNRIND), !is.na(ANRIND))

# ==============================================================================
# Create Shift Table for Each Parameter
# ==============================================================================

cat("Creating shift tables...\n")

# Select key lab parameters
key_params <- c("ALT", "AST", "BILI", "CREAT", "HGB", "WBC", "PLAT")

for (param in key_params) {
  
  cat(glue("  Processing {param}...\n"))
  
  param_data <- adlb %>%
    filter(PARAMCD == param)
  
  if (nrow(param_data) == 0) next
  
  # Create shift table
  shift_table <- param_data %>%
    count(TRT01P, BNRIND, ANRIND) %>%
    group_by(TRT01P, BNRIND) %>%
    mutate(
      Total = sum(n),
      pct = n / Total * 100,
      `n (%)` = sprintf("%d (%.1f%%)", n, pct)
    ) %>%
    ungroup() %>%
    select(TRT01P, BNRIND, ANRIND, `n (%)`)
  
  # Pivot to wide
  shift_wide <- shift_table %>%
    pivot_wider(
      id_cols = c(TRT01P, BNRIND),
      names_from = ANRIND,
      values_from = `n (%)`,
      values_fill = "0 (0.0%)"
    ) %>%
    arrange(TRT01P, factor(BNRIND, levels = c("LOW", "NORMAL", "HIGH")))
  
  # Further pivot by treatment
  shift_final <- shift_wide %>%
    pivot_wider(
      id_cols = BNRIND,
      names_from = TRT01P,
      values_from = c(LOW, NORMAL, HIGH),
      values_fill = "0 (0.0%)"
    )
  
  # Rename columns
  names(shift_final)[1] <- "Baseline"
  
  # Create table
  param_name <- unique(param_data$PARAM)[1]
  title <- glue("Table 14.3.5.{match(param, key_params)}\nLaboratory Shift Table: {param_name}\nSafety Population")
  
  footnotes <- c(
    "Shift from baseline to worst post-baseline value",
    "LOW = Below normal range; NORMAL = Within normal range; HIGH = Above normal range",
    glue("Generated: {Sys.Date()}")
  )
  
  shift_ft <- create_regulatory_table(shift_final, title, footnotes)
  
  # Export
  export_table_rtf(shift_ft, glue("Table_14_3_5_{param}_Shift"))
  export_table_docx(shift_ft, glue("Table_14_3_5_{param}_Shift"))
}

cat("\n✓ Lab shift tables generation complete!\n\n")

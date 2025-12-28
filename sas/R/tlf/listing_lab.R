# ==============================================================================
# Listing 16.2.3: Laboratory Test Results
# Script: listing_lab.R
# Purpose: Generate laboratory test results listing
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Listing 16.2.3: Laboratory Results\n")
cat("========================================\n\n")

# Read ADLB
adlb <- haven::read_sas(file.path(PATHS$adam, "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y") %>%
  arrange(TRT01P, USUBJID, PARAMCD, ADT)

# Prepare listing data
lab_listing_data <- adlb %>%
  mutate(
    `Test Date` = format(ADT, "%d%b%Y"),
    `Result` = sprintf("%.2f", AVAL),
    `Normal Range` = sprintf("%.1f - %.1f", ANRLO, ANRHI)
  ) %>%
  select(
    `Subject ID` = USUBJID,
    Treatment = TRT01P,
    `Test` = PARAM,
    `Test Date`,
    Result,
    Unit = AVALC,
    `Normal Range`,
    `Range Indicator` = ANRIND,
    `Baseline` = BASE
  )

# Create listing
title <- "Listing 16.2.3\nLaboratory Test Results\nSafety Population"

lab_listing <- create_listing(lab_listing_data, title, sort_vars = c("Treatment", "Subject ID", "Test", "Test Date"))

# Export
export_listing_rtf(lab_listing, "Listing_16_2_3_Laboratory_Results")

cat("\n✓ Listing 16.2.3 generation complete!\n\n")

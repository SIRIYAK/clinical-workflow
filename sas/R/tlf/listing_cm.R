# ==============================================================================
# Listing 16.2.2: Concomitant Medications
# Script: listing_cm.R
# Purpose: Generate concomitant medications listing
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Listing 16.2.2: Concomitant Medications\n")
cat("========================================\n\n")

# Read ADCM
adcm <- haven::read_sas(file.path(PATHS$adam, "adcm.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y") %>%
  arrange(TRT01P, USUBJID, ASTDT)

# Prepare listing data
cm_listing_data <- adcm %>%
  mutate(
    `Start Date` = format(ASTDT, "%d%b%Y"),
    `End Date` = if_else(!is.na(AENDT), format(AENDT, "%d%b%Y"), "Ongoing"),
    `Prior/Concomitant` = if_else(APRIFL == "Y", "Prior", "Concomitant")
  ) %>%
  select(
    `Subject ID` = USUBJID,
    Treatment = TRT01P,
    `Medication` = AVALC,
    `Start Date`,
    `End Date`,
    `Dose` = CMDOSE,
    `Unit` = CMDOSU,
    `Frequency` = CMDOSFRQ,
    `Route` = CMROUTE,
    `Prior/Concomitant`
  )

# Create listing
title <- "Listing 16.2.2\nConcomitant Medications\nSafety Population"

cm_listing <- create_listing(cm_listing_data, title, sort_vars = c("Treatment", "Subject ID", "Start Date"))

# Export
export_listing_rtf(cm_listing, "Listing_16_2_2_Concomitant_Medications")

cat("\n✓ Listing 16.2.2 generation complete!\n\n")

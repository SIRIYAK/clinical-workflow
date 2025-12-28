# ==============================================================================
# Listing 16.2.1: Adverse Events
# Script: listing_ae.R
# Purpose: Generate detailed AE listing
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Listing 16.2.1: Adverse Events\n")
cat("========================================\n\n")

# Read ADAE
adae <- haven::read_sas(file.path(PATHS$adam, "adae.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", TRTEMFL == "Y") %>%
  arrange(TRT01P, USUBJID, ASTDT)

cat(glue("Treatment-Emergent AEs: {nrow(adae)} events\n\n"))

# ==============================================================================
# Prepare Listing Data
# ==============================================================================

cat("Preparing listing data...\n")

ae_listing_data <- adae %>%
  mutate(
    `Start Date` = format(ASTDT, "%d%b%Y"),
    `End Date` = if_else(!is.na(AENDT), format(AENDT, "%d%b%Y"), "Ongoing"),
    Duration = if_else(!is.na(ADURN), paste(ADURN, "days"), "")
  ) %>%
  select(
    `Subject ID` = USUBJID,
    Treatment = TRT01P,
    `AE Term` = AETERM,
    `Start Date`,
    `End Date`,
    Duration,
    Severity = ASEV,
    Serious = ASER,
    Outcome = AOUT,
    Causality = AREL,
    `Action Taken` = AEACN
  )

# ==============================================================================
# Create Listing
# ==============================================================================

cat("Creating listing...\n")

title <- "Listing 16.2.1\nAdverse Events\nSafety Population"

ae_listing <- create_listing(
  data = ae_listing_data,
  title = title,
  sort_vars = c("Treatment", "Subject ID", "Start Date")
)

# ==============================================================================
# Export Listing
# ==============================================================================

cat("Exporting listing...\n")

export_listing_rtf(ae_listing, "Listing_16_2_1_Adverse_Events")

cat("\n========================================\n")
cat("✓ Listing 16.2.1 generation complete!\n")
cat("========================================\n\n")

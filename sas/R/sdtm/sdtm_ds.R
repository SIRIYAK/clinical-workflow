# ==============================================================================
# SDTM Domain Generation: DS (Disposition)
# Script: sdtm_ds.R
# Purpose: Generate SDTM DS domain from raw disposition data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_ds")

log_message("========================================")
log_message("SDTM DS Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw disposition data...")
ds_raw <- read_and_combine_sas(c("dsic.sas7bdat", "dsstat.sas7bdat"))

# Read DM for reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# Create SDTM DS structure
log_message("\n[Step 2] Creating SDTM DS structure...")

ds <- ds_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "DS") %>%
  dplyr::mutate(
    # Disposition term
    DSTERM = as.character(DSTERM),
    DSDECOD = toupper(DSDECOD),
    DSCAT = as.character(DSCAT),
    
    # Dates
    DSSTDTC = if_else(!is.na(DSSTDT), format_iso_date(DSSTDT), NA_character_),
    
    # Epoch
    EPOCH = as.character(EPOCH)
  ) %>%
  
  # Standardize disposition codes
  dplyr::mutate(
    DSDECOD = dplyr::case_when(
      stringr::str_detect(DSDECOD, "SCREEN") ~ "SCREENED",
      stringr::str_detect(DSDECOD, "RANDOM") ~ "RANDOMIZED",
      stringr::str_detect(DSDECOD, "COMPLET") ~ "COMPLETED",
      stringr::str_detect(DSDECOD, "DISCONTIN|WITHDRAW") ~ "DISCONTINUED",
      stringr::str_detect(DSDECOD, "DEATH") ~ "DEATH",
      TRUE ~ DSDECOD
    )
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "DSSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM for study day
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    DSSTDY = dplyr::case_when(
      is.na(DSSTDTC) ~ NA_real_,
      DSSTDTC >= RFSTDTC ~ as.numeric(difftime(DSSTDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(DSSTDTC, RFSTDTC, units = "days"))
    )
  ) %>%
  
  # Select SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD, DSCAT,
    DSSTDTC, DSSTDY, EPOCH,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created DS domain: {nrow(ds)} disposition records"))

# Validation
log_message("\n[Step 3] Validating DS domain...")
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSDECOD")
validate_required_vars(ds, required_vars, "DS")
check_duplicates(ds, c("STUDYID", "USUBJID", "DSSEQ"), "DS")

# Export
log_message("\n[Step 4] Exporting DS domain...")
export_dataset(ds, "ds", "sdtm", "Disposition")

# Generate BDM
log_message("\n[Step 5] Generating BDM specification...")
bdm_ds <- generate_bdm_spec(ds_raw, "DS", list(DSTERM = "DSTERM", DSDECOD = "DSDECOD", DSSTDT = "DSSTDTC"))
export_bdm(bdm_ds, "DS")

log_message("\n========================================")
log_message(glue("DS Domain Complete: {nrow(ds)} records"))
log_message(glue("Screened: {sum(ds$DSDECOD == 'SCREENED', na.rm = TRUE)}"))
log_message(glue("Randomized: {sum(ds$DSDECOD == 'RANDOMIZED', na.rm = TRUE)}"))
log_message(glue("Completed: {sum(ds$DSDECOD == 'COMPLETED', na.rm = TRUE)}"))
log_message(glue("Discontinued: {sum(ds$DSDECOD == 'DISCONTINUED', na.rm = TRUE)}"))
log_message("========================================")

close_log()
cat("\n✓ SDTM DS domain generation completed!\n\n")

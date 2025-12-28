# ==============================================================================
# SDTM Domain Generation: EX (Exposure)
# Script: sdtm_ex.R
# Purpose: Generate SDTM EX domain from raw exposure data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_ex")

log_message("========================================")
log_message("SDTM EX Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw exposure data...")
ex_raw <- read_sas_data("ecgen.sas7bdat")

# Read DM for reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# Create SDTM EX structure
log_message("\n[Step 2] Creating SDTM EX structure...")

ex <- ex_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "EX") %>%
  dplyr::mutate(
    # Treatment
    EXTRT = as.character(EXTRT),
    EXCAT = as.character(EXCAT),
    
    # Dates
    EXSTDTC = if_else(!is.na(EXSTDT), format_iso_date(EXSTDT), NA_character_),
    EXENDTC = if_else(!is.na(EXENDT), format_iso_date(EXENDT), NA_character_),
    
    # Dose information
    EXDOSE = as.numeric(EXDOSE),
    EXDOSU = as.character(EXDOSU),
    EXDOSFRM = as.character(EXDOSFRM),
    EXDOSFRQ = as.character(EXDOSFRQ),
    EXROUTE = toupper(EXROUTE)
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "EXSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM for study day
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    EXSTDY = dplyr::case_when(
      is.na(EXSTDTC) ~ NA_real_,
      EXSTDTC >= RFSTDTC ~ as.numeric(difftime(EXSTDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(EXSTDTC, RFSTDTC, units = "days"))
    ),
    EXENDY = dplyr::case_when(
      is.na(EXENDTC) ~ NA_real_,
      EXENDTC >= RFSTDTC ~ as.numeric(difftime(EXENDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(EXENDTC, RFSTDTC, units = "days"))
    ),
    EXDUR = if_else(!is.na(EXSTDTC) & !is.na(EXENDTC),
                    as.numeric(difftime(EXENDTC, EXSTDTC, units = "days")) + 1,
                    NA_real_)
  ) %>%
  
  # Select SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, EXSEQ, EXTRT, EXCAT,
    EXSTDTC, EXENDTC, EXSTDY, EXENDY, EXDUR,
    EXDOSE, EXDOSU, EXDOSFRM, EXDOSFRQ, EXROUTE,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created EX domain: {nrow(ex)} exposure records"))

# Validation
log_message("\n[Step 3] Validating EX domain...")
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "EXSEQ", "EXTRT", "EXSTDTC")
validate_required_vars(ex, required_vars, "EX")
check_duplicates(ex, c("STUDYID", "USUBJID", "EXSEQ"), "EX")

# Export
log_message("\n[Step 4] Exporting EX domain...")
export_dataset(ex, "ex", "sdtm", "Exposure")

# Generate BDM
log_message("\n[Step 5] Generating BDM specification...")
bdm_ex <- generate_bdm_spec(ex_raw, "EX", list(EXTRT = "EXTRT", EXSTDT = "EXSTDTC", EXENDT = "EXENDTC"))
export_bdm(bdm_ex, "EX")

log_message("\n========================================")
log_message(glue("EX Domain Complete: {nrow(ex)} records"))
log_message("========================================")

close_log()
cat("\n✓ SDTM EX domain generation completed!\n\n")

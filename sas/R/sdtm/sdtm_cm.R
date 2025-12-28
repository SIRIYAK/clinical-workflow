# ==============================================================================
# SDTM Domain Generation: CM (Concomitant Medications)
# Script: sdtm_cm.R
# Purpose: Generate SDTM CM domain from raw concomitant medications data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_cm")

log_message("========================================")
log_message("SDTM CM Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw concomitant medications data...")
cm_raw <- read_and_combine_sas(c("cmgen.sas7bdat", "cmatm.sas7bdat"))

# Read DM for reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT, RFXSTDTC = RFXSTDT)

# Create SDTM CM structure
log_message("\n[Step 2] Creating SDTM CM structure...")

cm <- cm_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "CM") %>%
  dplyr::mutate(
    # Medication term
    CMTRT = as.character(CMTRT),
    CMDECOD = as.character(CMDECOD),
    CMCAT = as.character(CMCAT),
    
    # Indication
    CMINDC = as.character(CMINDC),
    
    # Dates
    CMSTDTC = if_else(!is.na(CMSTDT), format_iso_date(CMSTDT), NA_character_),
    CMENDTC = if_else(!is.na(CMENDT), format_iso_date(CMENDT), NA_character_),
    
    # Dose information
    CMDOSE = as.numeric(CMDOSE),
    CMDOSU = as.character(CMDOSU),
    CMDOSFRM = as.character(CMDOSFRM),
    CMDOSFRQ = as.character(CMDOSFRQ),
    CMROUTE = toupper(CMROUTE)
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "CMSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM for study day and prior/concomitant flag
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    CMSTDY = dplyr::case_when(
      is.na(CMSTDTC) ~ NA_real_,
      CMSTDTC >= RFSTDTC ~ as.numeric(difftime(CMSTDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(CMSTDTC, RFSTDTC, units = "days"))
    ),
    CMENDY = dplyr::case_when(
      is.na(CMENDTC) ~ NA_real_,
      CMENDTC >= RFSTDTC ~ as.numeric(difftime(CMENDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(CMENDTC, RFSTDTC, units = "days"))
    ),
    
    # Prior/Concomitant flag
    CMOCCUR = "Y",
    CMPNCD = dplyr::case_when(
      is.na(CMSTDTC) | is.na(RFXSTDTC) ~ NA_character_,
      CMSTDTC < RFXSTDTC ~ "PRIOR",
      TRUE ~ "CONCOMITANT"
    )
  ) %>%
  
  # Select SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, CMSEQ, CMTRT, CMDECOD, CMCAT,
    CMINDC, CMSTDTC, CMENDTC, CMSTDY, CMENDY,
    CMDOSE, CMDOSU, CMDOSFRM, CMDOSFRQ, CMROUTE,
    CMOCCUR, CMPNCD,
    dplyr::everything(), -RFSTDTC, -RFXSTDTC
  )

log_message(glue("✓ Created CM domain: {nrow(cm)} concomitant medications"))

# Validation
log_message("\n[Step 3] Validating CM domain...")
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "CMSEQ", "CMTRT")
validate_required_vars(cm, required_vars, "CM")
check_duplicates(cm, c("STUDYID", "USUBJID", "CMSEQ"), "CM")

# Export
log_message("\n[Step 4] Exporting CM domain...")
export_dataset(cm, "cm", "sdtm", "Concomitant Medications")

# Generate BDM
log_message("\n[Step 5] Generating BDM specification...")
bdm_cm <- generate_bdm_spec(cm_raw, "CM", list(CMTRT = "CMTRT", CMDECOD = "CMDECOD", CMSTDT = "CMSTDTC"))
export_bdm(bdm_cm, "CM")

log_message("\n========================================")
log_message(glue("CM Domain Complete: {nrow(cm)} records"))
log_message(glue("Prior Medications: {sum(cm$CMPNCD == 'PRIOR', na.rm = TRUE)}"))
log_message(glue("Concomitant Medications: {sum(cm$CMPNCD == 'CONCOMITANT', na.rm = TRUE)}"))
log_message("========================================")

close_log()
cat("\n✓ SDTM CM domain generation completed!\n\n")

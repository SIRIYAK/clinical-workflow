# ==============================================================================
# ADaM Dataset Generation: ADCM (Concomitant Medications Analysis Dataset)
# Script: adam_adcm.R
# Purpose: Generate ADCM using admiral package
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("adam_adcm")

log_message("========================================")
log_message("ADaM ADCM Generation")
log_message("========================================")

log_message("\n[Step 1] Reading ADSL and CM...")

adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>% tibble::as_tibble()
cm <- haven::read_sas(file.path(PATHS$sdtm, "cm.sas7bdat")) %>% tibble::as_tibble()

log_message(glue("  ADSL: {nrow(adsl)} subjects"))
log_message(glue("  CM: {nrow(cm)} concomitant medication records"))

log_message("\n[Step 2] Merging CM with ADSL...")

adcm <- cm %>%
  dplyr::left_join(
    adsl %>% dplyr::select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, 
                          TRTSDT, TRTEDT, SAFFL, AGE, SEX, RACE),
    by = c("STUDYID", "USUBJID")
  )

log_message("\n[Step 3] Deriving analysis variables...")

adcm <- adcm %>%
  dplyr::mutate(
    # Analysis dates
    ASTDT = lubridate::ymd(CMSTDTC),
    AENDT = lubridate::ymd(CMENDTC),
    ASTDY = CMSTDY,
    AENDY = CMENDY,
    
    # Parameter
    PARAMCD = "CMTRT",
    PARAM = "Concomitant Medication",
    PARCAT1 = CMCAT,
    PARCAT2 = CMDECOD,
    
    # Analysis value
    AVALC = CMTRT,
    
    # Prior/Concomitant flags
    APRIFL = if_else(CMPNCD == "PRIOR", "Y", "N"),
    ACONFL = if_else(CMPNCD == "CONCOMITANT", "Y", "N"),
    
    # Occurrence flag
    AOCCFL = if_else(CMOCCUR == "Y", "Y", "N")
  )

# Derive first occurrence per subject
log_message("\n[Step 4] Deriving occurrence flags...")

adcm <- adcm %>%
  dplyr::group_by(USUBJID, CMDECOD) %>%
  dplyr::mutate(
    AOCCPFL = if_else(row_number() == 1, "Y", "N")
  ) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(USUBJID) %>%
  dplyr::mutate(
    AOCC01FL = if_else(row_number() == 1, "Y", "N")
  ) %>%
  dplyr::ungroup()

log_message("\n[Step 5] Finalizing ADCM structure...")

adcm <- adcm %>%
  dplyr::select(
    STUDYID, USUBJID, CMSEQ,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTEDT,
    PARAMCD, PARAM, PARCAT1, PARCAT2,
    ASTDT, AENDT, ASTDY, AENDY,
    AVALC, CMDOSE, CMDOSU, CMDOSFRQ, CMROUTE,
    APRIFL, ACONFL, AOCCFL, AOCCPFL, AOCC01FL, SAFFL,
    AGE, SEX, RACE,
    dplyr::everything()
  )

log_message(glue("✓ Created ADCM: {nrow(adcm)} concomitant medication records"))

log_message("\n[Step 6] Validating ADCM...")
validate_required_vars(adcm, c("STUDYID", "USUBJID", "PARAMCD"), "ADCM")

log_message("\n[Step 7] Exporting ADCM...")
export_dataset(adcm, "adcm", "adam", "Analysis Dataset Concomitant Medications")

log_message("\n========================================")
log_message("ADCM Generation Complete")
log_message(glue("Total Records: {nrow(adcm)}"))
log_message(glue("Prior Medications: {sum(adcm$APRIFL == 'Y')}"))
log_message(glue("Concomitant Medications: {sum(adcm$ACONFL == 'Y')}"))
log_message("========================================")

close_log()
cat("\n✓ ADaM ADCM generation completed!\n\n")

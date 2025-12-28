# ==============================================================================
# ADaM Dataset Generation: ADEG (ECG Analysis Dataset)
# Script: adam_adeg.R
# Purpose: Generate ADEG using admiral package
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("adam_adeg")

log_message("========================================")
log_message("ADaM ADEG Generation")
log_message("========================================")

log_message("\n[Step 1] Reading ADSL and EG...")

adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>% tibble::as_tibble()
eg <- haven::read_sas(file.path(PATHS$sdtm, "eg.sas7bdat")) %>% tibble::as_tibble()

log_message(glue("  ADSL: {nrow(adsl)} subjects"))
log_message(glue("  EG: {nrow(eg)} ECG records"))

log_message("\n[Step 2] Merging EG with ADSL...")

adeg <- eg %>%
  dplyr::left_join(
    adsl %>% dplyr::select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, 
                          TRTSDT, TRTEDT, SAFFL, AGE, SEX, RACE),
    by = c("STUDYID", "USUBJID")
  )

log_message("\n[Step 3] Deriving analysis variables...")

adeg <- adeg %>%
  dplyr::mutate(
    ADT = lubridate::ymd(EGDTC),
    ADY = EGDY,
    PARAMCD = EGTESTCD,
    PARAM = EGTEST,
    AVAL = EGSTRESN,
    AVALC = EGORRES
  )

log_message("\n[Step 4] Deriving baseline values...")

adeg <- adeg %>%
  dplyr::group_by(USUBJID, PARAMCD) %>%
  dplyr::arrange(ADT) %>%
  dplyr::mutate(
    ABLFL = if_else(ADT <= TRTSDT & row_number() == max(row_number()[ADT <= TRTSDT]), "Y", "N", missing = "N")
  ) %>%
  dplyr::ungroup()

baseline_vals <- adeg %>%
  dplyr::filter(ABLFL == "Y") %>%
  dplyr::select(USUBJID, PARAMCD, BASE = AVAL, BASEC = AVALC)

adeg <- adeg %>%
  dplyr::left_join(baseline_vals, by = c("USUBJID", "PARAMCD"))

log_message("\n[Step 5] Deriving change from baseline...")

adeg <- adeg %>%
  dplyr::mutate(
    CHG = if_else(!is.na(AVAL) & !is.na(BASE), AVAL - BASE, NA_real_),
    PCHG = if_else(!is.na(CHG) & BASE != 0, (CHG / BASE) * 100, NA_real_),
    ANL01FL = if_else(ADT > TRTSDT & !is.na(AVAL), "Y", "N"),
    
    # QTc-specific categorical analysis
    CRIT1 = dplyr::case_when(
      PARAMCD == "QTCF" & AVAL > 500 ~ "QTcF > 500 msec",
      PARAMCD == "QTCF" & AVAL > 480 ~ "QTcF > 480 msec",
      PARAMCD == "QTCF" & AVAL > 450 ~ "QTcF > 450 msec",
      TRUE ~ NA_character_
    ),
    CRIT1FL = if_else(!is.na(CRIT1), "Y", "N")
  )

log_message("\n[Step 6] Finalizing ADEG structure...")

adeg <- adeg %>%
  dplyr::select(
    STUDYID, USUBJID, EGSEQ,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTEDT,
    PARAMCD, PARAM,
    ADT, ADY, AVAL, AVALC,
    BASE, BASEC, CHG, PCHG,
    CRIT1, CRIT1FL,
    ABLFL, ANL01FL, SAFFL,
    AGE, SEX, RACE,
    dplyr::everything()
  )

log_message(glue("✓ Created ADEG: {nrow(adeg)} ECG records"))

log_message("\n[Step 7] Validating ADEG...")
validate_required_vars(adeg, c("STUDYID", "USUBJID", "PARAMCD"), "ADEG")

log_message("\n[Step 8] Exporting ADEG...")
export_dataset(adeg, "adeg", "adam", "Analysis Dataset ECG")

log_message("\n========================================")
log_message("ADEG Generation Complete")
log_message(glue("Total Records: {nrow(adeg)}"))
log_message(glue("QTcF > 500 msec: {sum(adeg$CRIT1 == 'QTcF > 500 msec', na.rm = TRUE)}"))
log_message("========================================")

close_log()
cat("\n✓ ADaM ADEG generation completed!\n\n")

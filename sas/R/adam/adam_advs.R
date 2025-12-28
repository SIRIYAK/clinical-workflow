# ==============================================================================
# ADaM Dataset Generation: ADVS (Vital Signs Analysis Dataset)
# Script: adam_advs.R
# Purpose: Generate ADVS using admiral package
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("adam_advs")

log_message("========================================")
log_message("ADaM ADVS Generation")
log_message("========================================")

log_message("\n[Step 1] Reading ADSL and VS...")

adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>% tibble::as_tibble()
vs <- haven::read_sas(file.path(PATHS$sdtm, "vs.sas7bdat")) %>% tibble::as_tibble()

log_message(glue("  ADSL: {nrow(adsl)} subjects"))
log_message(glue("  VS: {nrow(vs)} vital signs records"))

log_message("\n[Step 2] Merging VS with ADSL...")

advs <- vs %>%
  dplyr::left_join(
    adsl %>% dplyr::select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, 
                          TRTSDT, TRTEDT, SAFFL, AGE, SEX, RACE),
    by = c("STUDYID", "USUBJID")
  )

log_message("\n[Step 3] Deriving analysis variables...")

advs <- advs %>%
  dplyr::mutate(
    ADT = lubridate::ymd(VSDTC),
    ADY = VSDY,
    PARAMCD = VSTESTCD,
    PARAM = VSTEST,
    AVAL = VSSTRESN,
    AVALC = VSORRES
  )

log_message("\n[Step 4] Deriving baseline values...")

advs <- advs %>%
  dplyr::group_by(USUBJID, PARAMCD) %>%
  dplyr::arrange(ADT) %>%
  dplyr::mutate(
    ABLFL = if_else(ADT <= TRTSDT & row_number() == max(row_number()[ADT <= TRTSDT]), "Y", "N", missing = "N")
  ) %>%
  dplyr::ungroup()

baseline_vals <- advs %>%
  dplyr::filter(ABLFL == "Y") %>%
  dplyr::select(USUBJID, PARAMCD, BASE = AVAL, BASEC = AVALC)

advs <- advs %>%
  dplyr::left_join(baseline_vals, by = c("USUBJID", "PARAMCD"))

log_message("\n[Step 5] Deriving change from baseline...")

advs <- advs %>%
  dplyr::mutate(
    CHG = if_else(!is.na(AVAL) & !is.na(BASE), AVAL - BASE, NA_real_),
    PCHG = if_else(!is.na(CHG) & BASE != 0, (CHG / BASE) * 100, NA_real_),
    ANL01FL = if_else(ADT > TRTSDT & !is.na(AVAL), "Y", "N")
  )

log_message("\n[Step 6] Finalizing ADVS structure...")

advs <- advs %>%
  dplyr::select(
    STUDYID, USUBJID, VSSEQ,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTEDT,
    PARAMCD, PARAM,
    ADT, ADY, AVAL, AVALC,
    BASE, BASEC, CHG, PCHG,
    ABLFL, ANL01FL, SAFFL,
    AGE, SEX, RACE,
    dplyr::everything()
  )

log_message(glue("✓ Created ADVS: {nrow(advs)} vital signs records"))

log_message("\n[Step 7] Validating ADVS...")
validate_required_vars(advs, c("STUDYID", "USUBJID", "PARAMCD"), "ADVS")

log_message("\n[Step 8] Exporting ADVS...")
export_dataset(advs, "advs", "adam", "Analysis Dataset Vital Signs")

log_message("\n========================================")
log_message("ADVS Generation Complete")
log_message(glue("Total Records: {nrow(advs)}"))
log_message(glue("Baseline Records: {sum(advs$ABLFL == 'Y')}"))
log_message("========================================")

close_log()
cat("\n✓ ADaM ADVS generation completed!\n\n")

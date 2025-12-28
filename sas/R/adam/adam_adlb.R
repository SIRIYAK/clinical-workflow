# ==============================================================================
# ADaM Dataset Generation: ADLB (Laboratory Analysis Dataset)
# Script: adam_adlb.R
# Purpose: Generate ADLB using admiral package
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("adam_adlb")

log_message("========================================")
log_message("ADaM ADLB Generation")
log_message("========================================")

# Read required datasets
log_message("\n[Step 1] Reading ADSL and LB...")

adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>% tibble::as_tibble()
lb <- haven::read_sas(file.path(PATHS$sdtm, "lb.sas7bdat")) %>% tibble::as_tibble()

log_message(glue("  ADSL: {nrow(adsl)} subjects"))
log_message(glue("  LB: {nrow(lb)} laboratory records"))

# Merge LB with ADSL
log_message("\n[Step 2] Merging LB with ADSL...")

adlb <- lb %>%
  dplyr::left_join(
    adsl %>% dplyr::select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, 
                          TRTSDT, TRTEDT, SAFFL, AGE, SEX, RACE),
    by = c("STUDYID", "USUBJID")
  )

# Derive analysis variables
log_message("\n[Step 3] Deriving analysis variables...")

adlb <- adlb %>%
  dplyr::mutate(
    # Analysis date
    ADT = lubridate::ymd(LBDTC),
    ADY = LBDY,
    
    # Parameter code and name
    PARAMCD = LBTESTCD,
    PARAM = LBTEST,
    PARCAT1 = LBCAT,
    
    # Analysis value
    AVAL = LBSTRESN,
    AVALC = LBORRES,
    
    # Analysis normal range
    ANRLO = LBSTNRLO,
    ANRHI = LBSTNRHI,
    ANRIND = LBNRIND
  )

# Derive baseline
log_message("\n[Step 4] Deriving baseline values...")

adlb <- adlb %>%
  dplyr::group_by(USUBJID, PARAMCD) %>%
  dplyr::arrange(ADT) %>%
  dplyr::mutate(
    # Baseline flag (last value before or on treatment start date)
    ABLFL = if_else(ADT <= TRTSDT & row_number() == max(row_number()[ADT <= TRTSDT]), "Y", "N", missing = "N")
  ) %>%
  dplyr::ungroup()

# Get baseline values
baseline_vals <- adlb %>%
  dplyr::filter(ABLFL == "Y") %>%
  dplyr::select(USUBJID, PARAMCD, BASE = AVAL, BASEC = AVALC)

# Merge baseline back
adlb <- adlb %>%
  dplyr::left_join(baseline_vals, by = c("USUBJID", "PARAMCD"))

# Derive change from baseline
log_message("\n[Step 5] Deriving change from baseline...")

adlb <- adlb %>%
  dplyr::mutate(
    CHG = if_else(!is.na(AVAL) & !is.na(BASE), AVAL - BASE, NA_real_),
    PCHG = if_else(!is.na(CHG) & BASE != 0, (CHG / BASE) * 100, NA_real_)
  )

# Derive analysis flags
log_message("\n[Step 6] Deriving analysis flags...")

adlb <- adlb %>%
  dplyr::mutate(
    # Analysis flag (all post-baseline records)
    ANL01FL = if_else(ADT > TRTSDT & !is.na(AVAL), "Y", "N"),
    
    # Baseline normal range indicator
    BNRIND = if_else(ABLFL == "Y", ANRIND, NA_character_),
    
    # Shift from baseline
    SHIFT1 = if_else(!is.na(BNRIND) & !is.na(ANRIND), 
                     paste(BNRIND, "to", ANRIND), 
                     NA_character_)
  )

# Select and order variables
log_message("\n[Step 7] Finalizing ADLB structure...")

adlb <- adlb %>%
  dplyr::select(
    STUDYID, USUBJID, LBSEQ,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTEDT,
    PARAMCD, PARAM, PARCAT1,
    ADT, ADY, AVAL, AVALC,
    BASE, BASEC, CHG, PCHG,
    ANRLO, ANRHI, ANRIND, BNRIND, SHIFT1,
    ABLFL, ANL01FL, SAFFL,
    AGE, SEX, RACE,
    dplyr::everything()
  )

log_message(glue("✓ Created ADLB: {nrow(adlb)} laboratory records"))

# Validation
log_message("\n[Step 8] Validating ADLB...")
validate_required_vars(adlb, c("STUDYID", "USUBJID", "PARAMCD", "AVAL"), "ADLB")

# Export
log_message("\n[Step 9] Exporting ADLB...")
export_dataset(adlb, "adlb", "adam", "Analysis Dataset Laboratory")

log_message("\n========================================")
log_message("ADLB Generation Complete")
log_message(glue("Total Records: {nrow(adlb)}"))
log_message(glue("Baseline Records: {sum(adlb$ABLFL == 'Y')}"))
log_message(glue("Post-Baseline Records: {sum(adlb$ANL01FL == 'Y')}"))
log_message("========================================")

close_log()
cat("\n✓ ADaM ADLB generation completed!\n\n")

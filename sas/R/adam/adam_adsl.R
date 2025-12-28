# ==============================================================================
# ADaM Dataset Generation: ADSL (Subject-Level Analysis Dataset)
# Script: adam_adsl.R
# Purpose: Generate ADSL using admiral package
# ==============================================================================

# Source required scripts
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

# Initialize logging
init_log("adam_adsl")

log_message("========================================")
log_message("ADaM ADSL Generation")
log_message("========================================")

# ==============================================================================
# 1. Read SDTM Domains
# ==============================================================================

log_message("\n[Step 1] Reading SDTM domains...")

# Read DM
dm <- haven::read_sas(file.path(PATHS$sdtm, "dm.sas7bdat")) %>%
  tibble::as_tibble()

# Read DS (Disposition)
ds <- haven::read_sas(file.path(PATHS$sdtm, "ds.sas7bdat")) %>%
  tibble::as_tibble()

# Read EX (Exposure)
ex <- haven::read_sas(file.path(PATHS$sdtm, "ex.sas7bdat")) %>%
  tibble::as_tibble()

log_message(glue("  DM: {nrow(dm)} subjects"))
log_message(glue("  DS: {nrow(ds)} records"))
log_message(glue("  EX: {nrow(ex)} records"))

# ==============================================================================
# 2. Create ADSL Base
# ==============================================================================

log_message("\n[Step 2] Creating ADSL base from DM...")

adsl <- dm %>%
  dplyr::mutate(
    # Treatment variables (Planned)
    TRT01P = ARM,
    TRT01PN = as.numeric(factor(ARMCD)),
    TRT01A = ACTARM,
    TRT01AN = as.numeric(factor(ACTARMCD)),
    
    # Study dates
    TRTSDT = lubridate::ymd(RFXSTDTC),
    TRTEDT = lubridate::ymd(RFXENDTC),
    
    # Randomization date
    RANDDT = lubridate::ymd(RFICDTC),
    
    # Death information
    DTHDT = lubridate::ymd(DTHDTC),
    DTHFL = if_else(DTHFL == "Y", "Y", "N")
  )

# ==============================================================================
# 3. Derive Treatment Duration
# ==============================================================================

log_message("\n[Step 3] Deriving treatment duration...")

adsl <- adsl %>%
  dplyr::mutate(
    TRTDURD = if_else(!is.na(TRTSDT) & !is.na(TRTEDT),
                      as.numeric(difftime(TRTEDT, TRTSDT, units = "days")) + 1,
                      NA_real_)
  )

# ==============================================================================
# 4. Derive Disposition Information
# ==============================================================================

log_message("\n[Step 4] Deriving disposition information...")

# Get completion status
ds_comp <- ds %>%
  dplyr::filter(DSDECOD == "COMPLETED") %>%
  dplyr::select(USUBJID, DSSTDTC) %>%
  dplyr::mutate(EOSDT = lubridate::ymd(DSSTDTC)) %>%
  dplyr::select(USUBJID, EOSDT)

# Get discontinuation reason
ds_disc <- ds %>%
  dplyr::filter(DSDECOD == "DISCONTINUED") %>%
  dplyr::select(USUBJID, DSDECOD, DSTERM) %>%
  dplyr::mutate(
    DCSREAS = DSTERM,
    DCSREASP = DSDECOD
  ) %>%
  dplyr::select(USUBJID, DCSREAS, DCSREASP)

# Merge disposition info
adsl <- adsl %>%
  dplyr::left_join(ds_comp, by = "USUBJID") %>%
  dplyr::left_join(ds_disc, by = "USUBJID") %>%
  dplyr::mutate(
    EOSDT = if_else(is.na(EOSDT), TRTEDT, EOSDT),
    DCSREAS = if_else(is.na(DCSREAS), "COMPLETED", DCSREAS)
  )

# ==============================================================================
# 5. Derive Population Flags
# ==============================================================================

log_message("\n[Step 5] Deriving population flags...")

adsl <- adsl %>%
  dplyr::mutate(
    # Safety population: received at least one dose
    SAFFL = if_else(!is.na(TRTSDT), "Y", "N"),
    
    # Intent-to-treat population: randomized
    ITTFL = if_else(!is.na(RANDDT), "Y", "N"),
    
    # Per-protocol population: completed without major protocol deviations
    PPROTFL = if_else(DCSREAS == "COMPLETED", "Y", "N"),
    
    # Efficacy population (same as ITT for this example)
    EFFFL = ITTFL
  )

# ==============================================================================
# 6. Derive Baseline Characteristics
# ==============================================================================

log_message("\n[Step 6] Adding baseline characteristics...")

adsl <- adsl %>%
  dplyr::mutate(
    # Age categories
    AGEGR1 = dplyr::case_when(
      AGE < 18 ~ "<18",
      AGE >= 18 & AGE < 65 ~ "18-64",
      AGE >= 65 & AGE < 75 ~ "65-74",
      AGE >= 75 ~ ">=75",
      TRUE ~ NA_character_
    ),
    AGEGR1N = dplyr::case_when(
      AGE < 18 ~ 1,
      AGE >= 18 & AGE < 65 ~ 2,
      AGE >= 65 & AGE < 75 ~ 3,
      AGE >= 75 ~ 4,
      TRUE ~ NA_real_
    ),
    
    # Race categories
    RACEN = dplyr::case_when(
      RACE == "WHITE" ~ 1,
      RACE == "BLACK OR AFRICAN AMERICAN" ~ 2,
      RACE == "ASIAN" ~ 3,
      TRUE ~ 4
    )
  )

# ==============================================================================
# 7. Select and Order Variables
# ==============================================================================

log_message("\n[Step 7] Finalizing ADSL structure...")

adsl <- adsl %>%
  dplyr::select(
    # Identifiers
    STUDYID, USUBJID, SUBJID, SITEID,
    
    # Treatment variables
    TRT01P, TRT01PN, TRT01A, TRT01AN,
    
    # Dates
    TRTSDT, TRTEDT, TRTDURD, RANDDT, EOSDT, DTHDT,
    
    # Disposition
    DCSREAS, DCSREASP, DTHFL,
    
    # Population flags
    SAFFL, ITTFL, PPROTFL, EFFFL,
    
    # Demographics
    AGE, AGEU, AGEGR1, AGEGR1N, SEX, RACE, RACEN, ETHNIC, COUNTRY,
    
    # Everything else
    dplyr::everything()
  )

log_message(glue("✓ Created ADSL: {nrow(adsl)} subjects"))

# ==============================================================================
# 8. Validation
# ==============================================================================

log_message("\n[Step 8] Validating ADSL...")

# Required variables
required_vars <- c("STUDYID", "USUBJID", "TRT01P", "TRT01A", "SAFFL", "ITTFL")
validate_required_vars(adsl, required_vars, "ADSL")

# Check for duplicates
check_duplicates(adsl, c("STUDYID", "USUBJID"), "ADSL")

# ==============================================================================
# 9. Export
# ==============================================================================

log_message("\n[Step 9] Exporting ADSL...")

export_dataset(
  data = adsl,
  domain_name = "adsl",
  dataset_type = "adam",
  label = "Subject-Level Analysis Dataset"
)

# ==============================================================================
# Summary
# ==============================================================================

log_message("\n========================================")
log_message("ADSL Generation Complete")
log_message(glue("Total Subjects: {nrow(adsl)}"))
log_message(glue("Safety Population: {sum(adsl$SAFFL == 'Y')}"))
log_message(glue("ITT Population: {sum(adsl$ITTFL == 'Y')}"))
log_message(glue("Per-Protocol Population: {sum(adsl$PPROTFL == 'Y')}"))
log_message("========================================")

close_log()

cat("\n✓ ADaM ADSL generation completed successfully!\n\n")

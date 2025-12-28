# ==============================================================================
# ADaM Dataset Generation: ADAE (Adverse Events Analysis)
# Script: adam_adae.R
# Purpose: Generate ADAE using admiral package
# ==============================================================================

# Source required scripts
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

# Initialize logging
init_log("adam_adae")

log_message("========================================")
log_message("ADaM ADAE Generation")
log_message("========================================")

# ==============================================================================
# 1. Read Required Datasets
# ==============================================================================

log_message("\n[Step 1] Reading ADSL and AE...")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble()

# Read SDTM AE
ae <- haven::read_sas(file.path(PATHS$sdtm, "ae.sas7bdat")) %>%
  tibble::as_tibble()

log_message(glue("  ADSL: {nrow(adsl)} subjects"))
log_message(glue("  AE: {nrow(ae)} adverse events"))

# ==============================================================================
# 2. Merge AE with ADSL
# ==============================================================================

log_message("\n[Step 2] Merging AE with ADSL...")

adae <- ae %>%
  dplyr::left_join(
    adsl %>% dplyr::select(STUDYID, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, 
                          TRTSDT, TRTEDT, SAFFL, AGE, SEX, RACE),
    by = c("STUDYID", "USUBJID")
  )

# ==============================================================================
# 3. Derive Analysis Variables
# ==============================================================================

log_message("\n[Step 3] Deriving analysis variables...")

adae <- adae %>%
  dplyr::mutate(
    # Convert dates
    ASTDT = lubridate::ymd(AESTDTC),
    AENDT = lubridate::ymd(AEENDTC),
    
    # Analysis start/end day
    ASTDY = AESTDY,
    AENDY = AEENDY,
    
    # AE duration in days
    ADURN = if_else(!is.na(ASTDT) & !is.na(AENDT),
                    as.numeric(difftime(AENDT, ASTDT, units = "days")) + 1,
                    NA_real_),
    
    # Treatment-emergent flag
    TRTEMFL = if_else(
      !is.na(ASTDT) & !is.na(TRTSDT) & ASTDT >= TRTSDT,
      "Y", "N"
    ),
    
    # Analysis occurrence flags
    AOCC01FL = if_else(AESEQ == 1, "Y", "N"),  # First occurrence per subject
    AOCCPFL = "Y",  # Preferred term occurrence flag
    AOCCFL = "Y",   # Any occurrence flag
    
    # Severity numeric
    ASEVN = dplyr::case_when(
      AESEV == "MILD" ~ 1,
      AESEV == "MODERATE" ~ 2,
      AESEV == "SEVERE" ~ 3,
      TRUE ~ NA_real_
    ),
    ASEV = AESEV,
    
    # Serious flag numeric
    ASERN = if_else(AESER == "Y", 1, 0),
    ASER = AESER,
    
    # Outcome
    AOUT = AEOUT,
    
    # Causality
    AREL = AEREL,
    ARELN = if_else(AEREL == "RELATED", 1, 0),
    
    # CTC Grade
    ATOXGR = AETOXGR,
    ATOXGRN = as.numeric(AETOXGR)
  )

# ==============================================================================
# 4. Derive Analysis Flags
# ==============================================================================

log_message("\n[Step 4] Deriving analysis flags...")

adae <- adae %>%
  dplyr::group_by(USUBJID, AEDECOD) %>%
  dplyr::mutate(
    # First occurrence of preferred term per subject
    AOCCPFL = if_else(row_number() == 1, "Y", "N")
  ) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(USUBJID) %>%
  dplyr::mutate(
    # First AE per subject
    AOCC01FL = if_else(row_number() == 1, "Y", "N")
  ) %>%
  dplyr::ungroup()

# ==============================================================================
# 5. Add Parameter Information
# ==============================================================================

log_message("\n[Step 5] Adding parameter information...")

adae <- adae %>%
  dplyr::mutate(
    PARAMCD = "AETOT",
    PARAM = "Total Adverse Events",
    PARCAT1 = AEBODSYS,
    PARCAT2 = AEDECOD
  )

# ==============================================================================
# 6. Select and Order Variables
# ==============================================================================

log_message("\n[Step 6] Finalizing ADAE structure...")

adae <- adae %>%
  dplyr::select(
    # Identifiers
    STUDYID, USUBJID, AESEQ,
    
    # Treatment
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTEDT,
    
    # Parameters
    PARAMCD, PARAM, PARCAT1, PARCAT2,
    
    # AE terms
    AETERM, AEDECOD, AEBODSYS,
    
    # Dates and timing
    ASTDT, AENDT, ASTDY, AENDY, ADURN,
    
    # Severity and seriousness
    ASEV, ASEVN, ASER, ASERN,
    
    # Outcome and causality
    AOUT, AREL, ARELN,
    
    # Toxicity grade
    ATOXGR, ATOXGRN,
    
    # Flags
    TRTEMFL, AOCC01FL, AOCCPFL, AOCCFL, SAFFL,
    
    # Demographics
    AGE, SEX, RACE,
    
    # Everything else
    dplyr::everything()
  )

log_message(glue("✓ Created ADAE: {nrow(adae)} adverse events"))

# ==============================================================================
# 7. Validation
# ==============================================================================

log_message("\n[Step 7] Validating ADAE...")

# Required variables
required_vars <- c("STUDYID", "USUBJID", "PARAMCD", "TRTEMFL")
validate_required_vars(adae, required_vars, "ADAE")

# ==============================================================================
# 8. Export
# ==============================================================================

log_message("\n[Step 8] Exporting ADAE...")

export_dataset(
  data = adae,
  domain_name = "adae",
  dataset_type = "adam",
  label = "Adverse Events Analysis Dataset"
)

# ==============================================================================
# Summary
# ==============================================================================

log_message("\n========================================")
log_message("ADAE Generation Complete")
log_message(glue("Total AEs: {nrow(adae)}"))
log_message(glue("Treatment-Emergent AEs: {sum(adae$TRTEMFL == 'Y')}"))
log_message(glue("Serious AEs: {sum(adae$ASER == 'Y')}"))
log_message(glue("Related AEs: {sum(adae$AREL == 'RELATED', na.rm = TRUE)}"))
log_message("========================================")

close_log()

cat("\n✓ ADaM ADAE generation completed successfully!\n\n")

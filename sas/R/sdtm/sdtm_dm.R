# ==============================================================================
# SDTM Domain Generation: DM (Demographics)
# Script: sdtm_dm.R
# Purpose: Generate SDTM DM domain from raw demographics data
# ==============================================================================

# Source required scripts
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

# Initialize logging
init_log("sdtm_dm")

log_message("========================================")
log_message("SDTM DM Domain Generation")
log_message("========================================")

# ==============================================================================
# 1. Read Raw Data
# ==============================================================================

log_message("\n[Step 1] Reading raw demographics data...")

dm_raw <- read_sas_data("dmgen.sas7bdat")

# ==============================================================================
# 2. Create SDTM DM Structure
# ==============================================================================

log_message("\n[Step 2] Creating SDTM DM structure...")

dm <- dm_raw %>%
  # Derive STUDYID and USUBJID
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  
  # Add DOMAIN
  dplyr::mutate(DOMAIN = "DM") %>%
  
  # Map demographics variables
  dplyr::mutate(
    # Subject identifiers
    SUBJID = as.character(SUBJID),
    SITEID = as.character(SITEID),
    
    # Demographics
    AGE = as.numeric(AGE),
    AGEU = "YEARS",
    SEX = toupper(SEX),
    RACE = toupper(RACE),
    ETHNIC = toupper(ETHNIC),
    
    # Country and site
    COUNTRY = toupper(COUNTRY),
    
    # Randomization
    ARM = as.character(ARM),
    ARMCD = as.character(ARMCD),
    ACTARM = as.character(ACTARM),
    ACTARMCD = as.character(ACTARMCD),
    
    # Reference dates (convert to ISO 8601 format)
    RFSTDTC = if_else(!is.na(RFSTDT), format_iso_date(RFSTDT), NA_character_),
    RFENDTC = if_else(!is.na(RFENDT), format_iso_date(RFENDT), NA_character_),
    RFXSTDTC = if_else(!is.na(RFXSTDT), format_iso_date(RFXSTDT), NA_character_),
    RFXENDTC = if_else(!is.na(RFXENDT), format_iso_date(RFXENDT), NA_character_),
    RFICDTC = if_else(!is.na(RFICDT), format_iso_date(RFICDT), NA_character_),
    RFPENDTC = if_else(!is.na(RFPENDT), format_iso_date(RFPENDT), NA_character_),
    
    # Disposition
    DTHFL = if_else(toupper(DTHFL) == "Y", "Y", NA_character_),
    DTHDTC = if_else(!is.na(DTHDT), format_iso_date(DTHDT), NA_character_)
  ) %>%
  
  # Apply CDISC controlled terminology
  dplyr::mutate(
    SEX = dplyr::case_when(
      SEX %in% c("M", "MALE") ~ "M",
      SEX %in% c("F", "FEMALE") ~ "F",
      TRUE ~ "U"
    ),
    RACE = dplyr::case_when(
      stringr::str_detect(RACE, "WHITE") ~ "WHITE",
      stringr::str_detect(RACE, "BLACK|AFRICAN") ~ "BLACK OR AFRICAN AMERICAN",
      stringr::str_detect(RACE, "ASIAN") ~ "ASIAN",
      stringr::str_detect(RACE, "INDIAN|ALASKA") ~ "AMERICAN INDIAN OR ALASKA NATIVE",
      stringr::str_detect(RACE, "HAWAIIAN|PACIFIC") ~ "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER",
      TRUE ~ "OTHER"
    ),
    ETHNIC = dplyr::case_when(
      stringr::str_detect(ETHNIC, "HISPANIC|LATINO") ~ "HISPANIC OR LATINO",
      stringr::str_detect(ETHNIC, "NOT.*HISPANIC") ~ "NOT HISPANIC OR LATINO",
      TRUE ~ "NOT REPORTED"
    )
  ) %>%
  
  # Select and order SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, SUBJID, RFSTDTC, RFENDTC, RFXSTDTC, RFXENDTC,
    RFICDTC, RFPENDTC, DTHDTC, DTHFL, SITEID, AGE, AGEU, SEX, RACE, ETHNIC,
    ARMCD, ARM, ACTARMCD, ACTARM, COUNTRY,
    dplyr::everything()
  )

log_message(glue("✓ Created DM domain: {nrow(dm)} subjects"))

# ==============================================================================
# 3. Validation
# ==============================================================================

log_message("\n[Step 3] Validating DM domain...")

# Required variables
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "SUBJID", "RFSTDTC", "AGE", "SEX")
validate_required_vars(dm, required_vars, "DM")

# Check for duplicates
check_duplicates(dm, c("STUDYID", "USUBJID"), "DM")

# Data type validation
type_spec <- list(
  STUDYID = "character",
  USUBJID = "character",
  AGE = "numeric",
  SEX = "character"
)
validate_data_types(dm, type_spec, "DM")

# ==============================================================================
# 4. Export
# ==============================================================================

log_message("\n[Step 4] Exporting DM domain...")

export_dataset(
  data = dm,
  domain_name = "dm",
  dataset_type = "sdtm",
  label = "Demographics"
)

# ==============================================================================
# 5. Generate BDM Specification
# ==============================================================================

log_message("\n[Step 5] Generating BDM specification...")

bdm_dm <- generate_bdm_spec(
  source_data = dm_raw,
  target_domain = "DM",
  mapping_list = list(
    SUBJID = "SUBJID",
    SITEID = "SITEID",
    AGE = "AGE",
    SEX = "SEX",
    RACE = "RACE",
    ETHNIC = "ETHNIC",
    COUNTRY = "COUNTRY",
    ARM = "ARM",
    ARMCD = "ARMCD"
  )
)

export_bdm(bdm_dm, "DM")

# ==============================================================================
# Summary
# ==============================================================================

log_message("\n========================================")
log_message("DM Domain Generation Complete")
log_message(glue("Total Subjects: {nrow(dm)}"))
log_message(glue("Total Variables: {ncol(dm)}"))
log_message("========================================")

close_log()

cat("\n✓ SDTM DM domain generation completed successfully!\n\n")

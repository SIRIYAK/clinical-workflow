# ==============================================================================
# SDTM Domain Generation: EG (ECG Test Results)
# Script: sdtm_eg.R
# Purpose: Generate SDTM EG domain from raw ECG data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_eg")

log_message("========================================")
log_message("SDTM EG Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw ECG data...")
eg_raw <- read_and_combine_sas(c("eggen.sas7bdat", "egholt.sas7bdat"))

# Read DM for reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# Create SDTM EG structure
log_message("\n[Step 2] Creating SDTM EG structure...")

eg <- eg_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "EG") %>%
  dplyr::mutate(
    # ECG test code and name
    EGTESTCD = toupper(EGTESTCD),
    EGTEST = as.character(EGTEST),
    EGCAT = as.character(EGCAT),
    
    # Results
    EGORRES = as.character(EGORRES),
    EGORRESU = as.character(EGORRESU),
    EGSTRESN = as.numeric(EGSTRESN),
    EGSTRESU = as.character(EGSTRESU),
    
    # Dates
    EGDTC = if_else(!is.na(EGDT), format_iso_date(EGDT), NA_character_),
    
    # Position
    EGPOS = toupper(EGPOS),
    
    # Method
    EGMETHOD = as.character(EGMETHOD)
  ) %>%
  
  # Standardize test codes
  dplyr::mutate(
    EGTESTCD = dplyr::case_when(
      stringr::str_detect(EGTESTCD, "HR|HEART") ~ "HR",
      stringr::str_detect(EGTESTCD, "QT$") ~ "QT",
      stringr::str_detect(EGTESTCD, "QTC|QTCF") ~ "QTCF",
      stringr::str_detect(EGTESTCD, "PR") ~ "PR",
      stringr::str_detect(EGTESTCD, "QRS") ~ "QRS",
      stringr::str_detect(EGTESTCD, "RR") ~ "RR",
      TRUE ~ EGTESTCD
    ),
    EGTEST = dplyr::case_when(
      EGTESTCD == "HR" ~ "Heart Rate",
      EGTESTCD == "QT" ~ "QT Duration",
      EGTESTCD == "QTCF" ~ "QT Corrected Fridericia",
      EGTESTCD == "PR" ~ "PR Duration",
      EGTESTCD == "QRS" ~ "QRS Duration",
      EGTESTCD == "RR" ~ "RR Duration",
      TRUE ~ EGTEST
    )
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "EGSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM for study day
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    EGDY = dplyr::case_when(
      is.na(EGDTC) ~ NA_real_,
      EGDTC >= RFSTDTC ~ as.numeric(difftime(EGDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(EGDTC, RFSTDTC, units = "days"))
    )
  ) %>%
  
  # Select SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, EGSEQ, EGTESTCD, EGTEST, EGCAT,
    EGORRES, EGORRESU, EGSTRESN, EGSTRESU,
    EGDTC, EGDY, EGPOS, EGMETHOD,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created EG domain: {nrow(eg)} ECG records"))

# Validation
log_message("\n[Step 3] Validating EG domain...")
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "EGSEQ", "EGTESTCD", "EGDTC")
validate_required_vars(eg, required_vars, "EG")
check_duplicates(eg, c("STUDYID", "USUBJID", "EGTESTCD", "EGSEQ"), "EG")

# Export
log_message("\n[Step 4] Exporting EG domain...")
export_dataset(eg, "eg", "sdtm", "ECG Test Results")

# Generate BDM
log_message("\n[Step 5] Generating BDM specification...")
bdm_eg <- generate_bdm_spec(eg_raw, "EG", list(EGTESTCD = "EGTESTCD", EGTEST = "EGTEST", EGORRES = "EGORRES"))
export_bdm(bdm_eg, "EG")

log_message("\n========================================")
log_message(glue("EG Domain Complete: {nrow(eg)} records"))
log_message("========================================")

close_log()
cat("\n✓ SDTM EG domain generation completed!\n\n")

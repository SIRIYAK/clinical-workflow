# ==============================================================================
# SDTM Domain Generation: VS (Vital Signs)
# Script: sdtm_vs.R
# Purpose: Generate SDTM VS domain from raw vital signs data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_vs")

log_message("========================================")
log_message("SDTM VS Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw vital signs data...")
vs_raw <- read_sas_data("vsgen.sas7bdat")

# Read DM for reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# Create SDTM VS structure
log_message("\n[Step 2] Creating SDTM VS structure...")

vs <- vs_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "VS") %>%
  dplyr::mutate(
    # VS test code and name
    VSTESTCD = toupper(VSTESTCD),
    VSTEST = as.character(VSTEST),
    
    # Result
    VSORRES = as.character(VSORRES),
    VSORRESU = as.character(VSORRESU),
    VSSTRESN = as.numeric(VSSTRESN),
    VSSTRESU = as.character(VSSTRESU),
    
    # Dates
    VSDTC = if_else(!is.na(VSDT), format_iso_date(VSDT), NA_character_),
    
    # Position
    VSPOS = toupper(VSPOS),
    
    # Location
    VSLOC = toupper(VSLOC)
  ) %>%
  
  # Standardize test codes
  dplyr::mutate(
    VSTESTCD = dplyr::case_when(
      stringr::str_detect(VSTESTCD, "SYS|SYSBP") ~ "SYSBP",
      stringr::str_detect(VSTESTCD, "DIA|DIABP") ~ "DIABP",
      stringr::str_detect(VSTESTCD, "PULSE|HR|HEART") ~ "PULSE",
      stringr::str_detect(VSTESTCD, "TEMP") ~ "TEMP",
      stringr::str_detect(VSTESTCD, "RESP") ~ "RESP",
      stringr::str_detect(VSTESTCD, "WEIGHT|WT") ~ "WEIGHT",
      stringr::str_detect(VSTESTCD, "HEIGHT|HT") ~ "HEIGHT",
      stringr::str_detect(VSTESTCD, "BMI") ~ "BMI",
      TRUE ~ VSTESTCD
    ),
    VSTEST = dplyr::case_when(
      VSTESTCD == "SYSBP" ~ "Systolic Blood Pressure",
      VSTESTCD == "DIABP" ~ "Diastolic Blood Pressure",
      VSTESTCD == "PULSE" ~ "Pulse Rate",
      VSTESTCD == "TEMP" ~ "Temperature",
      VSTESTCD == "RESP" ~ "Respiratory Rate",
      VSTESTCD == "WEIGHT" ~ "Weight",
      VSTESTCD == "HEIGHT" ~ "Height",
      VSTESTCD == "BMI" ~ "Body Mass Index",
      TRUE ~ VSTEST
    )
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "VSSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM for study day
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    VSDY = dplyr::case_when(
      is.na(VSDTC) ~ NA_real_,
      VSDTC >= RFSTDTC ~ as.numeric(difftime(VSDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(VSDTC, RFSTDTC, units = "days"))
    )
  ) %>%
  
  # Select SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, VSSEQ, VSTESTCD, VSTEST,
    VSORRES, VSORRESU, VSSTRESN, VSSTRESU,
    VSDTC, VSDY, VSPOS, VSLOC,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created VS domain: {nrow(vs)} vital signs records"))

# Validation
log_message("\n[Step 3] Validating VS domain...")
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "VSSEQ", "VSTESTCD", "VSDTC")
validate_required_vars(vs, required_vars, "VS")
check_duplicates(vs, c("STUDYID", "USUBJID", "VSTESTCD", "VSSEQ"), "VS")

# Export
log_message("\n[Step 4] Exporting VS domain...")
export_dataset(vs, "vs", "sdtm", "Vital Signs")

# Generate BDM
log_message("\n[Step 5] Generating BDM specification...")
bdm_vs <- generate_bdm_spec(vs_raw, "VS", list(VSTESTCD = "VSTESTCD", VSTEST = "VSTEST", VSORRES = "VSORRES"))
export_bdm(bdm_vs, "VS")

log_message("\n========================================")
log_message(glue("VS Domain Complete: {nrow(vs)} records"))
log_message("========================================")

close_log()
cat("\n✓ SDTM VS domain generation completed!\n\n")

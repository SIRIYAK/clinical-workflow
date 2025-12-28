# ==============================================================================
# SDTM Domain Generation: LB (Laboratory)
# Script: sdtm_lb.R
# Purpose: Generate SDTM LB domain from raw laboratory data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_lb")

log_message("========================================")
log_message("SDTM LB Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw laboratory data...")
lb_raw <- read_sas_data("lblocal.sas7bdat")

# Read DM for reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# Create SDTM LB structure
log_message("\n[Step 2] Creating SDTM LB structure...")

lb <- lb_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "LB") %>%
  dplyr::mutate(
    # Lab test code and name
    LBTESTCD = toupper(LBTESTCD),
    LBTEST = as.character(LBTEST),
    LBCAT = as.character(LBCAT),
    
    # Results
    LBORRES = as.character(LBORRES),
    LBORRESU = as.character(LBORRESU),
    LBSTRESN = as.numeric(LBSTRESN),
    LBSTRESU = as.character(LBSTRESU),
    
    # Normal ranges
    LBSTNRLO = as.numeric(LBSTNRLO),
    LBSTNRHI = as.numeric(LBSTNRHI),
    
    # Normal range indicator
    LBNRIND = dplyr::case_when(
      is.na(LBSTRESN) ~ NA_character_,
      LBSTRESN < LBSTNRLO ~ "LOW",
      LBSTRESN > LBSTNRHI ~ "HIGH",
      TRUE ~ "NORMAL"
    ),
    
    # Dates
    LBDTC = if_else(!is.na(LBDT), format_iso_date(LBDT), NA_character_),
    
    # Specimen
    LBSPEC = toupper(LBSPEC),
    LBMETHOD = as.character(LBMETHOD)
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "LBSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM for study day
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    LBDY = dplyr::case_when(
      is.na(LBDTC) ~ NA_real_,
      LBDTC >= RFSTDTC ~ as.numeric(difftime(LBDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(LBDTC, RFSTDTC, units = "days"))
    )
  ) %>%
  
  # Select SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, LBSEQ, LBTESTCD, LBTEST, LBCAT,
    LBORRES, LBORRESU, LBSTRESN, LBSTRESU,
    LBSTNRLO, LBSTNRHI, LBNRIND,
    LBDTC, LBDY, LBSPEC, LBMETHOD,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created LB domain: {nrow(lb)} laboratory records"))

# Validation
log_message("\n[Step 3] Validating LB domain...")
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "LBSEQ", "LBTESTCD", "LBDTC")
validate_required_vars(lb, required_vars, "LB")
check_duplicates(lb, c("STUDYID", "USUBJID", "LBTESTCD", "LBSEQ"), "LB")

# Export
log_message("\n[Step 4] Exporting LB domain...")
export_dataset(lb, "lb", "sdtm", "Laboratory Test Results")

# Generate BDM
log_message("\n[Step 5] Generating BDM specification...")
bdm_lb <- generate_bdm_spec(lb_raw, "LB", list(LBTESTCD = "LBTESTCD", LBTEST = "LBTEST", LBORRES = "LBORRES"))
export_bdm(bdm_lb, "LB")

log_message("\n========================================")
log_message(glue("LB Domain Complete: {nrow(lb)} records"))
log_message("========================================")

close_log()
cat("\n✓ SDTM LB domain generation completed!\n\n")

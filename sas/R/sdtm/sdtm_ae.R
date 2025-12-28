# ==============================================================================
# SDTM Domain Generation: AE (Adverse Events)
# Script: sdtm_ae.R
# Purpose: Generate SDTM AE domain from raw adverse events data
# ==============================================================================

# Source required scripts
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

# Initialize logging
init_log("sdtm_ae")

log_message("========================================")
log_message("SDTM AE Domain Generation")
log_message("========================================")

# ==============================================================================
# 1. Read Raw Data
# ==============================================================================

log_message("\n[Step 1] Reading raw adverse events data...")

ae_raw <- read_sas_data("aesae.sas7bdat")

# Read DM for USUBJID and reference dates
dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# ==============================================================================
# 2. Create SDTM AE Structure
# ==============================================================================

log_message("\n[Step 2] Creating SDTM AE structure...")

ae <- ae_raw %>%
  # Derive STUDYID and USUBJID
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  
  # Add DOMAIN
  dplyr::mutate(DOMAIN = "AE") %>%
  
  # Map AE variables
  dplyr::mutate(
    # AE term
    AETERM = as.character(AETERM),
    AEDECOD = as.character(AEDECOD),  # MedDRA Preferred Term
    AEBODSYS = as.character(AEBODSYS), # MedDRA System Organ Class
    AESOC = as.character(AESOC),
    
    # AE dates (convert to ISO 8601)
    AESTDTC = if_else(!is.na(AESTDT), format_iso_date(AESTDT), NA_character_),
    AEENDTC = if_else(!is.na(AEENDT), format_iso_date(AEENDT), NA_character_),
    
    # AE severity and outcome
    AESEV = toupper(AESEV),
    AESER = if_else(toupper(AESER) == "Y", "Y", "N"),
    AEOUT = toupper(AEOUT),
    
    # Causality
    AEREL = toupper(AEREL),
    AEACN = toupper(AEACN),  # Action taken
    
    # Toxicity grade (CTCAE)
    AETOXGR = as.character(AETOXGR),
    
    # Flags
    AESDTH = if_else(toupper(AESDTH) == "Y", "Y", NA_character_),
    AESHOSP = if_else(toupper(AESHOSP) == "Y", "Y", NA_character_),
    AESLIFE = if_else(toupper(AESLIFE) == "Y", "Y", NA_character_),
    AESDISAB = if_else(toupper(AESDISAB) == "Y", "Y", NA_character_)
  ) %>%
  
  # Apply CDISC controlled terminology
  dplyr::mutate(
    AESEV = dplyr::case_when(
      AESEV %in% c("MILD", "1") ~ "MILD",
      AESEV %in% c("MODERATE", "2") ~ "MODERATE",
      AESEV %in% c("SEVERE", "3") ~ "SEVERE",
      TRUE ~ AESEV
    ),
    AEOUT = dplyr::case_when(
      stringr::str_detect(AEOUT, "RECOVER.*RESOLV") ~ "RECOVERED/RESOLVED",
      stringr::str_detect(AEOUT, "RECOVERING") ~ "RECOVERING/RESOLVING",
      stringr::str_detect(AEOUT, "NOT.*RECOVER") ~ "NOT RECOVERED/NOT RESOLVED",
      stringr::str_detect(AEOUT, "SEQUELAE") ~ "RECOVERED/RESOLVED WITH SEQUELAE",
      stringr::str_detect(AEOUT, "FATAL|DEATH") ~ "FATAL",
      TRUE ~ "UNKNOWN"
    ),
    AEREL = dplyr::case_when(
      AEREL %in% c("Y", "YES", "RELATED") ~ "RELATED",
      AEREL %in% c("N", "NO", "NOT RELATED") ~ "NOT RELATED",
      TRUE ~ "NOT RELATED"
    )
  ) %>%
  
  # Derive sequence number
  derive_seq(seq_var = "AESEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  
  # Merge with DM to get reference start date for study day derivation
  dplyr::left_join(dm, by = "USUBJID") %>%
  
  # Derive study day
  dplyr::mutate(
    AESTDY = dplyr::case_when(
      is.na(AESTDTC) ~ NA_real_,
      AESTDTC >= RFSTDTC ~ as.numeric(difftime(AESTDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(AESTDTC, RFSTDTC, units = "days"))
    ),
    AEENDY = dplyr::case_when(
      is.na(AEENDTC) ~ NA_real_,
      AEENDTC >= RFSTDTC ~ as.numeric(difftime(AEENDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(AEENDTC, RFSTDTC, units = "days"))
    ),
    AEDUR = if_else(!is.na(AESTDTC) & !is.na(AEENDTC),
                    as.numeric(difftime(AEENDTC, AESTDTC, units = "days")),
                    NA_real_)
  ) %>%
  
  # Select and order SDTM variables
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, AESEQ, AETERM, AEDECOD, AEBODSYS, AESOC,
    AESTDTC, AEENDTC, AESTDY, AEENDY, AEDUR,
    AESEV, AESER, AEOUT, AEREL, AEACN, AETOXGR,
    AESDTH, AESHOSP, AESLIFE, AESDISAB,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created AE domain: {nrow(ae)} adverse events"))

# ==============================================================================
# 3. Validation
# ==============================================================================

log_message("\n[Step 3] Validating AE domain...")

# Required variables
required_vars <- c("STUDYID", "DOMAIN", "USUBJID", "AESEQ", "AETERM", "AESTDTC")
validate_required_vars(ae, required_vars, "AE")

# Check for duplicates
check_duplicates(ae, c("STUDYID", "USUBJID", "AESEQ"), "AE")

# ==============================================================================
# 4. Export
# ==============================================================================

log_message("\n[Step 4] Exporting AE domain...")

export_dataset(
  data = ae,
  domain_name = "ae",
  dataset_type = "sdtm",
  label = "Adverse Events"
)

# ==============================================================================
# 5. Generate BDM Specification
# ==============================================================================

log_message("\n[Step 5] Generating BDM specification...")

bdm_ae <- generate_bdm_spec(
  source_data = ae_raw,
  target_domain = "AE",
  mapping_list = list(
    AETERM = "AETERM",
    AEDECOD = "AEDECOD",
    AESTDT = "AESTDTC",
    AEENDT = "AEENDTC",
    AESEV = "AESEV",
    AESER = "AESER",
    AEOUT = "AEOUT"
  )
)

export_bdm(bdm_ae, "AE")

# ==============================================================================
# Summary
# ==============================================================================

log_message("\n========================================")
log_message("AE Domain Generation Complete")
log_message(glue("Total AEs: {nrow(ae)}"))
log_message(glue("Serious AEs: {sum(ae$AESER == 'Y', na.rm = TRUE)}"))
log_message(glue("Fatal AEs: {sum(ae$AEOUT == 'FATAL', na.rm = TRUE)}"))
log_message("========================================")

close_log()

cat("\n✓ SDTM AE domain generation completed successfully!\n\n")

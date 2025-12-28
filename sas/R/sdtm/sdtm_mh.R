# ==============================================================================
# SDTM Domain Generation: MH (Medical History)
# Script: sdtm_mh.R
# Purpose: Generate SDTM MH domain from raw medical history data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_mh")

log_message("========================================")
log_message("SDTM MH Domain Generation")
log_message("========================================")

# Read raw data
log_message("\n[Step 1] Reading raw medical history data...")
mh_raw <- read_and_combine_sas(c("mhgen.sas7bdat", "mhsdd.sas7bdat"))

dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

# Create SDTM MH structure
log_message("\n[Step 2] Creating SDTM MH structure...")

mh <- mh_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "MH") %>%
  dplyr::mutate(
    MHTERM = as.character(MHTERM),
    MHDECOD = as.character(MHDECOD),
    MHCAT = as.character(MHCAT),
    MHBODSYS = as.character(MHBODSYS),
    MHSTDTC = if_else(!is.na(MHSTDT), format_iso_date(MHSTDT), NA_character_),
    MHENDTC = if_else(!is.na(MHENDT), format_iso_date(MHENDT), NA_character_),
    MHENRF = if_else(toupper(MHENRF) == "Y" | is.na(MHENDTC), "Y", "N")
  ) %>%
  derive_seq(seq_var = "MHSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    MHSTDY = dplyr::case_when(
      is.na(MHSTDTC) ~ NA_real_,
      MHSTDTC >= RFSTDTC ~ as.numeric(difftime(MHSTDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(MHSTDTC, RFSTDTC, units = "days"))
    )
  ) %>%
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, MHSEQ, MHTERM, MHDECOD, MHCAT, MHBODSYS,
    MHSTDTC, MHENDTC, MHSTDY, MHENRF,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created MH domain: {nrow(mh)} medical history records"))

log_message("\n[Step 3] Validating MH domain...")
validate_required_vars(mh, c("STUDYID", "DOMAIN", "USUBJID", "MHSEQ", "MHTERM"), "MH")
check_duplicates(mh, c("STUDYID", "USUBJID", "MHSEQ"), "MH")

log_message("\n[Step 4] Exporting MH domain...")
export_dataset(mh, "mh", "sdtm", "Medical History")

log_message("\n[Step 5] Generating BDM specification...")
bdm_mh <- generate_bdm_spec(mh_raw, "MH", list(MHTERM = "MHTERM", MHDECOD = "MHDECOD"))
export_bdm(bdm_mh, "MH")

log_message("\n========================================")
log_message(glue("MH Domain Complete: {nrow(mh)} records"))
log_message("========================================")

close_log()
cat("\n✓ SDTM MH domain generation completed!\n\n")

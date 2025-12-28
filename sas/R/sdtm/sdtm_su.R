# ==============================================================================
# SDTM Domain Generation: SU (Substance Use)
# Script: sdtm_su.R
# Purpose: Generate SDTM SU domain from raw substance use data
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("sdtm_su")

log_message("========================================")
log_message("SDTM SU Domain Generation")
log_message("========================================")

log_message("\n[Step 1] Reading raw substance use data...")
su_raw <- read_sas_data("sugen.sas7bdat")

dm <- read_sas_data("dmgen.sas7bdat") %>%
  derive_usubjid() %>%
  dplyr::select(USUBJID, RFSTDTC = RFSTDT)

log_message("\n[Step 2] Creating SDTM SU structure...")

su <- su_raw %>%
  derive_usubjid(study_id = STUDY_CONFIG$study_id) %>%
  dplyr::mutate(DOMAIN = "SU") %>%
  dplyr::mutate(
    SUTRT = as.character(SUTRT),
    SUCAT = as.character(SUCAT),
    SUSTDTC = if_else(!is.na(SUSTDT), format_iso_date(SUSTDT), NA_character_),
    SUENDTC = if_else(!is.na(SUENDT), format_iso_date(SUENDT), NA_character_),
    SUOCCUR = if_else(toupper(SUOCCUR) == "Y", "Y", "N"),
    SUDOSE = as.character(SUDOSE),
    SUDOSFRQ = as.character(SUDOSFRQ)
  ) %>%
  derive_seq(seq_var = "SUSEQ", by_vars = c("STUDYID", "USUBJID")) %>%
  dplyr::left_join(dm, by = "USUBJID") %>%
  dplyr::mutate(
    SUSTDY = dplyr::case_when(
      is.na(SUSTDTC) ~ NA_real_,
      SUSTDTC >= RFSTDTC ~ as.numeric(difftime(SUSTDTC, RFSTDTC, units = "days")) + 1,
      TRUE ~ as.numeric(difftime(SUSTDTC, RFSTDTC, units = "days"))
    )
  ) %>%
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, SUSEQ, SUTRT, SUCAT,
    SUSTDTC, SUENDTC, SUSTDY, SUOCCUR, SUDOSE, SUDOSFRQ,
    dplyr::everything(), -RFSTDTC
  )

log_message(glue("✓ Created SU domain: {nrow(su)} substance use records"))

log_message("\n[Step 3] Validating SU domain...")
validate_required_vars(su, c("STUDYID", "DOMAIN", "USUBJID", "SUSEQ"), "SU")
check_duplicates(su, c("STUDYID", "USUBJID", "SUSEQ"), "SU")

log_message("\n[Step 4] Exporting SU domain...")
export_dataset(su, "su", "sdtm", "Substance Use")

log_message("\n[Step 5] Generating BDM specification...")
bdm_su <- generate_bdm_spec(su_raw, "SU", list(SUTRT = "SUTRT", SUCAT = "SUCAT"))
export_bdm(bdm_su, "SU")

log_message("\n========================================")
log_message(glue("SU Domain Complete: {nrow(su)} records"))
log_message("========================================")

close_log()
cat("\n✓ SDTM SU domain generation completed!\n\n")

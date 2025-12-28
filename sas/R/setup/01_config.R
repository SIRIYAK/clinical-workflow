# ==============================================================================
# SDTM/ADaM/BDM Automation Framework
# Script: 01_config.R
# Purpose: Configuration settings for the automation framework
# ==============================================================================

# ==============================================================================
# Study Metadata
# ==============================================================================
STUDY_CONFIG <- list(
  study_id = "DQCC_STUDY",
  protocol = "DQCC-001",
  sponsor = "Your Sponsor Name",
  indication = "Oncology",
  phase = "Phase 2",
  cdisc_ct_version = "2023-12-15",
  sdtm_version = "1.7",
  adam_version = "1.3"
)

# ==============================================================================
# File Paths
# ==============================================================================
PATHS <- list(
  # Root directory
  root = here::here(),
  
  # Input data
  raw_sas = here::here("sas"),
  
  # Output directories
  sdtm = here::here("data", "sdtm"),
  adam = here::here("data", "adam"),
  bdm = here::here("specs", "bdm"),
  reports = here::here("outputs", "reports"),
  logs = here::here("outputs", "logs"),
  
  # Config directories
  metadata = here::here("config", "metadata")
)

# ==============================================================================
# SDTM Domain Configuration
# ==============================================================================
SDTM_DOMAINS <- list(
  # Special Purpose Domains
  dm = list(
    name = "Demographics",
    source = "dmgen.sas7bdat",
    required = TRUE,
    key_vars = c("STUDYID", "USUBJID")
  ),
  
  # Events Domains
  ae = list(
    name = "Adverse Events",
    source = "aesae.sas7bdat",
    required = TRUE,
    key_vars = c("STUDYID", "USUBJID", "AESEQ")
  ),
  
  ds = list(
    name = "Disposition",
    source = c("dsic.sas7bdat", "dsstat.sas7bdat"),
    required = TRUE,
    key_vars = c("STUDYID", "USUBJID", "DSSEQ")
  ),
  
  mh = list(
    name = "Medical History",
    source = c("mhgen.sas7bdat", "mhsdd.sas7bdat"),
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "MHSEQ")
  ),
  
  # Interventions Domains
  cm = list(
    name = "Concomitant Medications",
    source = c("cmgen.sas7bdat", "cmatm.sas7bdat"),
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "CMSEQ")
  ),
  
  ex = list(
    name = "Exposure",
    source = "ecgen.sas7bdat",
    required = TRUE,
    key_vars = c("STUDYID", "USUBJID", "EXSEQ")
  ),
  
  su = list(
    name = "Substance Use",
    source = "sugen.sas7bdat",
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "SUSEQ")
  ),
  
  # Findings Domains
  vs = list(
    name = "Vital Signs",
    source = "vsgen.sas7bdat",
    required = TRUE,
    key_vars = c("STUDYID", "USUBJID", "VSTESTCD", "VSSEQ")
  ),
  
  lb = list(
    name = "Laboratory",
    source = "lblocal.sas7bdat",
    required = TRUE,
    key_vars = c("STUDYID", "USUBJID", "LBTESTCD", "LBSEQ")
  ),
  
  eg = list(
    name = "ECG",
    source = c("eggen.sas7bdat", "egholt.sas7bdat"),
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "EGTESTCD", "EGSEQ")
  ),
  
  ec = list(
    name = "Exposure as Collected",
    source = "ecgen.sas7bdat",
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "ECSEQ")
  ),
  
  pr = list(
    name = "Procedures",
    source = c("prgen.sas7bdat", "pratradi.sas7bdat", "pratsurg.sas7bdat", "prpe.sas7bdat"),
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "PRSEQ")
  ),
  
  rs = list(
    name = "Disease Response",
    source = c("rsecog.sas7bdat", "rseval.sas7bdat"),
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "RSSEQ")
  ),
  
  tu = list(
    name = "Tumor Identification",
    source = "tutr.sas7bdat",
    required = FALSE,
    key_vars = c("STUDYID", "USUBJID", "TUSEQ")
  )
)

# ==============================================================================
# ADaM Dataset Configuration
# ==============================================================================
ADAM_DATASETS <- list(
  adsl = list(
    name = "Subject-Level Analysis Dataset",
    type = "ADSL",
    required = TRUE,
    depends_on = c("dm", "ds", "ex")
  ),
  
  adae = list(
    name = "Adverse Events Analysis",
    type = "OCCDS",
    required = TRUE,
    depends_on = c("adsl", "ae")
  ),
  
  adlb = list(
    name = "Laboratory Analysis",
    type = "BDS",
    required = TRUE,
    depends_on = c("adsl", "lb")
  ),
  
  advs = list(
    name = "Vital Signs Analysis",
    type = "BDS",
    required = FALSE,
    depends_on = c("adsl", "vs")
  ),
  
  adeg = list(
    name = "ECG Analysis",
    type = "BDS",
    required = FALSE,
    depends_on = c("adsl", "eg")
  ),
  
  adcm = list(
    name = "Concomitant Medications Analysis",
    type = "OCCDS",
    required = FALSE,
    depends_on = c("adsl", "cm")
  )
)

# ==============================================================================
# Validation Rules
# ==============================================================================
VALIDATION_RULES <- list(
  # SDTM validation thresholds
  sdtm = list(
    max_missing_pct = 5,        # Maximum % of missing required variables
    max_invalid_dates = 0,       # Maximum number of invalid dates
    max_ct_violations = 0        # Maximum controlled terminology violations
  ),
  
  # ADaM validation thresholds
  adam = list(
    max_missing_baseline = 0,    # Maximum missing baseline values
    max_traceability_issues = 0  # Maximum traceability issues to SDTM
  )
)

# ==============================================================================
# Controlled Terminology
# ==============================================================================
CT_CONFIG <- list(
  # Common CDISC CT codelists
  sex = c("M" = "Male", "F" = "Female", "U" = "Unknown"),
  race = c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN", "AMERICAN INDIAN OR ALASKA NATIVE", 
           "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER", "OTHER", "UNKNOWN"),
  ethnic = c("HISPANIC OR LATINO", "NOT HISPANIC OR LATINO", "UNKNOWN", "NOT REPORTED"),
  country = c("USA", "CAN", "GBR", "DEU", "FRA", "ITA", "ESP"),
  
  # AE outcomes
  aeout = c("RECOVERED/RESOLVED", "RECOVERING/RESOLVING", "NOT RECOVERED/NOT RESOLVED", 
            "RECOVERED/RESOLVED WITH SEQUELAE", "FATAL", "UNKNOWN"),
  
  # AE severity
  aesev = c("MILD", "MODERATE", "SEVERE"),
  
  # Units
  units_weight = "kg",
  units_height = "cm",
  units_temp = "C",
  units_bp = "mmHg"
)

# ==============================================================================
# Logging Configuration
# ==============================================================================
LOG_CONFIG <- list(
  log_level = "INFO",  # DEBUG, INFO, WARN, ERROR
  log_to_file = TRUE,
  log_to_console = TRUE,
  timestamp_format = "%Y-%m-%d %H:%M:%S"
)

# ==============================================================================
# Export Configuration
# ==============================================================================
EXPORT_CONFIG <- list(
  # XPT export settings
  xpt_version = "5",
  xpt_label_max_length = 40,
  xpt_var_name_max_length = 8,
  
  # Also export as SAS7BDAT?
  export_sas = TRUE,
  
  # Also export as CSV?
  export_csv = TRUE
)

# ==============================================================================
# Print Configuration Summary
# ==============================================================================
print_config <- function() {
  cat("\n========================================\n")
  cat("Configuration Summary\n")
  cat("========================================\n")
  cat("Study ID:", STUDY_CONFIG$study_id, "\n")
  cat("Protocol:", STUDY_CONFIG$protocol, "\n")
  cat("SDTM Version:", STUDY_CONFIG$sdtm_version, "\n")
  cat("ADaM Version:", STUDY_CONFIG$adam_version, "\n")
  cat("CDISC CT Version:", STUDY_CONFIG$cdisc_ct_version, "\n")
  cat("\nSDTM Domains:", length(SDTM_DOMAINS), "\n")
  cat("ADaM Datasets:", length(ADAM_DATASETS), "\n")
  cat("========================================\n\n")
}

# Print configuration on load
print_config()

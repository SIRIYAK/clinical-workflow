# =============================================================================
# Configuration File for R Data Validation Checks
# Author: Siriyak
# Date: 2026-01-14
# Description: Central configuration for all validation checks including
#              paths, study parameters, and validation settings
# =============================================================================

# Study Parameters --------------------------------------------------------
COMP <- "Compound_A"
STUDY <- "DQCCStudy"

# Path Configuration ------------------------------------------------------
# Note: Update these paths based on your environment

# CDB Library Path
CDB_LIB_PATH <- "/study_data/cdb_library/veeva"

# ALSC Library Path
ALSC_LIB_PATH <- "/study_data/alsc_library"

# Output Path for Reports
OUT_PATH <- "/study_data/outputs/validation_reports"

# Alternative paths for Windows development (comment/uncomment as needed)
# CDB_LIB_PATH <- "d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/cdb_lib"
# ALSC_LIB_PATH <- "d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/alsc_lib"
# OUT_PATH <- "d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/outputs"

# Validation Settings -----------------------------------------------------

# Include length issue checks (Y/N)
LENGTH_ISSUE_NEEDED <- "Y"

# Date format for output files
DATE_FORMAT <- "%d%b%Y"

# Maximum allowable missing percentage for warnings
MAX_MISSING_PCT <- 10

# Duplicate record threshold
DUPLICATE_THRESHOLD <- 0

# Output Settings ---------------------------------------------------------

# Excel output settings
EXCEL_STYLE_HEADER <- TRUE
EXCEL_FREEZE_PANES <- TRUE

# Log file settings
LOG_ENABLED <- TRUE
LOG_LEVEL <- "INFO" # DEBUG, INFO, WARNING, ERROR

# Quality Check Thresholds ------------------------------------------------

# Minimum observations for comparison
MIN_OBS_THRESHOLD <- 1

# Variable name matching (case sensitive or not)
VAR_MATCH_CASE_SENSITIVE <- FALSE

# Type mismatch tolerance
TYPE_MISMATCH_ALLOWED <- FALSE

# Session Information -----------------------------------------------------
SESSION_START <- Sys.time()
SESSION_ID <- format(SESSION_START, "%Y%m%d_%H%M%S")

# Helper Functions --------------------------------------------------------

#' Get current date string for file naming
#' @return Character string in format specified by DATE_FORMAT
get_date_string <- function() {
    format(Sys.Date(), DATE_FORMAT)
}

#' Get output file path
#' @param filename Base filename
#' @return Full path to output file
get_output_path <- function(filename) {
    file.path(OUT_PATH, filename)
}

#' Print configuration summary
print_config <- function() {
    cat("\n=== Data Validation Configuration ===\n")
    cat("Study:", STUDY, "\n")
    cat("Compound:", COMP, "\n")
    cat("CDB Path:", CDB_LIB_PATH, "\n")
    cat("ALSC Path:", ALSC_LIB_PATH, "\n")
    cat("Output Path:", OUT_PATH, "\n")
    cat("Session ID:", SESSION_ID, "\n")
    cat("====================================\n\n")
}

# CDISC Library Configuration ---------------------------------------------

# CDISC Library Base URL
CDISC_API_BASE_URL <- "https://library.cdisc.org/api/mdr"

# CDISC Library API Key
# Try to get from environment variable first
CDISC_API_KEY <- Sys.getenv("CDISC_API_KEY")

# Default Standards to fetch
CDISC_SDTM_VERSION <- "sdtmig-3-2" # SDTM Implementation Guide 3.2
CDISC_ADAM_VERSION <- "adamig-1-1" # ADaM Implementation Guide 1.1

# Path for caching downloaded standards
CDISC_CACHE_DIR <- file.path(dirname(OUT_PATH), "specs")
# Ensure directory exists, if safe to create
if (!dir.exists(CDISC_CACHE_DIR)) {
    try(dir.create(CDISC_CACHE_DIR, recursive = TRUE), silent = TRUE)
}

# check_HMPR101.R
# Check HMPR101: Procedure Start Date vs Informed Consent Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR101 (FYI3.txt)

library(dplyr)
library(lubridate)

#' Check HMPR101: Procedure Start Date must be > informed consent date (DS).
#' Update logic (based on macro comments): pr_start_date <= ds_start_date
#' "Objective - Procedure Start Date must be > informed consent date."
#' But code says: "pr_start_date <= ds_start_date" is the filter?
#' SAS code: if ... and pr_start_date <= ds_start_date ; -> This usually filters for the INVALID records in these macros.
#' So IF Procedure Date <= DS Date -> Flag as Error?
#' That contradicts "Procedure Start Date must be > informed consent date".
#' If valid is > IC, then invalid is <= IC. So logic holds.
#'
#' @param hmpr_data HMPR dataset
#' @param ds_data DS (Disposition) dataset
#' @return Data frame with invalid records
check_HMPR101 <- function(hmpr_data, ds_data) {
    message("Running check_HMPR101...")

    # Required vars
    # HMPR: PRSTDAT...
    # DS: DSSTDAT...

    # Helper to construct date from components (simulated)
    # Ideally should use utils or existing dates.
    # Assuming standard date vars might exist as replacements or using components if present.

    # Ensure HMPR_DATA has PR_START_DATE
    if (!"PR_START_DATE" %in% names(hmpr_data)) {
        if (all(c("PRSTDATYY", "PRSTDATMO", "PRSTDATDD") %in% names(hmpr_data))) {
            hmpr_data <- hmpr_data %>%
                mutate(PR_START_DATE = as.Date(paste(PRSTDATYY, PRSTDATMO, PRSTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else if ("PRSTDAT" %in% names(hmpr_data)) {
            hmpr_data <- hmpr_data %>% mutate(PR_START_DATE = as.Date(PRSTDAT))
        } else {
            message("Error: HMPR_DATA is missing PR_START_DATE or its components (PRSTDATYY, PRSTDATMO, PRSTDATDD, or PRSTDAT).")
            return(NULL)
        }
    }

    # Ensure DS_DATA has CMSTDAT (Consent Date)
    if (!"CMSTDAT" %in% names(ds_data)) {
        if (all(c("CMSTDATYY", "CMSTDATMO", "CMSTDATDD") %in% names(ds_data))) {
            ds_data <- ds_data %>%
                mutate(CMSTDAT = as.Date(paste(CMSTDATYY, CMSTDATMO, CMSTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else if ("DSSTDAT" %in% names(ds_data)) { # Fallback to DSSTDAT if CMSTDAT not found
            ds_data <- ds_data %>% mutate(CMSTDAT = as.Date(DSSTDAT))
        } else {
            message("Error: DS_DATA is missing CMSTDAT or its components (CMSTDATYY, CMSTDATMO, CMSTDATDD, or DSSTDAT).")
            return(NULL)
        }
    }

    # Check HMPR procedure performed
    hmpr_proc <- hmpr_data %>%
        filter(toupper(PROCCUR) == "Y") %>%
        filter(!is.na(PR_START_DATE)) %>%
        select(SUBJID, PROCCUR, PR_START_DATE)

    # Get Informed Consent Date
    # Assuming CMSTDAT is the informed consent date.
    # If there's a specific filter for consent (e.g., DSSCAT == "STUDY"), it should be applied here.
    ds_ic <- ds_data %>%
        filter(!is.na(CMSTDAT)) %>%
        select(SUBJID, CMSTDAT)

    # Join and filter for invalid records
    invalid_records <- hmpr_proc %>%
        inner_join(ds_ic, by = "SUBJID") %>%
        filter(PR_START_DATE <= CMSTDAT) %>%
        select(SUBJID, PR_START_DATE, CMSTDAT)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HMPR101: Found", nrow(invalid_records), "records with Procedure Date <= Consent Date"))
    }

    return(invalid_records)
}

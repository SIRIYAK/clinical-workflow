# check_HMPR108.R
# Check HMPR108: Steatosis consistency
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR108 (FYI3.txt)

library(dplyr)

#' Check HMPR108: If Steatosis is selected (HMPRES1_B) then Fatty Infiltration result (HMPRES4) must be completed.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR108 <- function(hmpr_data) {
    message("Running check_HMPR108...")

    # Required variables: SUBJID, HMPRES1_B, HMPRES4
    req_vars <- c("subjid", "hmpres1_b", "hmpres4")
    missing_vars <- req_vars[!req_vars %in% names(hmpr_data)]

    if (length(missing_vars) > 0) {
        warning(paste("check_HMPR108: Missing variables in HMPR dataset:", paste(missing_vars, collapse = ", ")))
        return(NULL)
    }

    # SAS Logic: if UPCASE(HMPRES1_B) = 'STEATOSIS' and missing(HMPRES4) then output;

    invalid_records <- hmpr_data %>%
        filter(toupper(HMPRES1_B) == "STEATOSIS") %>%
        filter(is.na(HMPRES4) | trimws(HMPRES4) == "") %>%
        select(SUBJID, HMPRES1_B, HMPRES4)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HMPR108: Found", nrow(invalid_records), "records with missing fatty infiltration result"))
    }

    return(invalid_records)
}

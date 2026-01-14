# check_HAIRRFU204.R
# Check HAIRRFU204: Alternative Cause Selection
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HAIRRFU204 (FYI3.txt)

library(dplyr)
library(tidyr)

#' Check HAIRRFU204: Is there a clear alternative cause... = Yes (HAIRRFUR1=Y)
#' then at least one alternative cause should be selected (HAIRRFUR2A-E).
#'
#' @param hair_data HAIRRFU dataset
#' @return Data frame with invalid records
check_HAIRRFU204 <- function(hair_data) {
    message("Running check_HAIRRFU204...")

    # Vars: HAIRRFUR1 (Yes/No), HAIRRFUR2A, 2B, 2C, 2D, 2E
    req_vars <- c("HAIRCAUS", "HAIRC_A", "HAIRC_B", "HAIRC_C", "HAIRC_D", "HAIRC_E", "HAIRC_F", "HAIRC_G")
    if (!all(req_vars %in% names(hair_data))) {
        # return(NULL) # Or warn
    }

    # Check for at least one existing Cause variable to check against
    cause_vars <- c("HAIRC_A", "HAIRC_B", "HAIRC_C", "HAIRC_D", "HAIRC_E", "HAIRC_F", "HAIRC_G")
    existing_cause_vars <- intersect(names(hair_data), cause_vars)

    if (length(existing_cause_vars) == 0) {
        return(NULL)
    }

    # SAS Logic: if UPCASE(HAIRCAUS) = 'YES' and missing(all causes) then output;

    invalid_records <- hair_data %>%
        filter(toupper(HAIRCAUS) == "YES") %>%
        # Check if ALL existing cause variables are NA or missing/blank
        filter(if_all(all_of(existing_cause_vars), ~ is.na(.) | trimws(as.character(.)) == "")) %>%
        select(SUBJID, HAIRCAUS, any_of(existing_cause_vars))

    if (nrow(invalid_records) > 0) {
        message(paste("check_HAIRRFU204: Found", nrow(invalid_records), "records. 'Yes' selected but no alternative cause specified."))
    }

    return(invalid_records)
}

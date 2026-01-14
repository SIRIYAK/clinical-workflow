# check_HAIRRFU205.R
# Check HAIRRFU205: Alternative Cause 'Other' positive check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HAIRRFU205 (FYI3.txt)

library(dplyr)

#' Check HAIRRFU205: Alternative Cause: Other was selected (implied) validation.
#' SAS logic: if not missing(HAIRRFUR2EOTH) and missing(HAIRRFUR2E);
#' This logic flags: "Specify text exists" BUT "Checkbox NOT selected".
#' Objective: "Other was selected then the specify field should not be blank." <- Wait, SAS comment says this.
#' But code logic usually flags the ERROR condition.
#' Code: `if not missing(OTH) and missing(CHECKBOX)` -> Error: "Provided details but didn't check the box".
#'
#' @param hair_data HAIRRFU dataset
#' @return Data frame with invalid records
check_HAIRRFU205 <- function(hair_data) {
    message("Running check_HAIRRFU205...")

    req_vars <- c("HAIRC_G", "HAIRC_OTH")
    if (!all(req_vars %in% names(hair_data))) {
        return(NULL)
    }

    # SAS Logic: if HAIRC_OTH ne ' ' and UPCASE(HAIRC_G) ne 'OTHER' then output;
    # (Assuming HAIRC_G is the 'Other' checkbox/result corresponding to Other Specify)

    invalid_records <- hair_data %>%
        filter(trimws(HAIRC_OTH) != "" & !is.na(HAIRC_OTH)) %>%
        filter(toupper(HAIRC_G) != "OTHER") %>% # Or whatever the value for 'Other' checkbox is (usually 'Other' or 'Checked' or 'Y')
        # Based on macro: if HAIRC_OTH ne ' ' and UPCASE(HAIRC_G) ne 'OTHER'
        select(SUBJID, HAIRC_G, HAIRC_OTH)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HAIRRFU205: Found", nrow(invalid_records), "records. Details provided but 'Other' not checked."))
    }

    return(invalid_records)
}

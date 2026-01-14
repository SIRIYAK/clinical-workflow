# check_HAIRRFU207.R
# Check HAIRRFU207: Similar symptoms 'Yes' validation
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HAIRRFU207 (FYI3.txt)

library(dplyr)

#' Check HAIRRFU207: If Have similar symptoms been observed with other drugs? = Yes (HAIRRFUR57=Y),
#' then the specify field (HAIRRFUR57OTH) should not be blank.
#'
#' @param hair_data HAIRRFU dataset
#' @return Data frame with invalid records
check_HAIRRFU207 <- function(hair_data) {
    message("Running check_HAIRRFU207...")

    req_vars <- c("SIMSX", "SIMSX_OTH")
    if (!all(req_vars %in% names(hair_data))) {
        return(NULL)
    }

    # SAS Logic: if UPCASE(SIMSX) = 'YES' and SIMSX_OTH = ' ' then output;

    invalid_records <- hair_data %>%
        filter(toupper(SIMSX) == "YES") %>%
        filter(trimws(SIMSX_OTH) == "" | is.na(SIMSX_OTH)) %>%
        select(SUBJID, SIMSX, SIMSX_OTH)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HAIRRFU207: Found", nrow(invalid_records), "records with missing 'Yes' specification"))
    }

    return(invalid_records)
}

# check_HAIRRFU208.R
# Check HAIRRFU208: Similar symptoms 'No' validation
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HAIRRFU208 (FYI3.txt)

library(dplyr)

#' Check HAIRRFU208: If Have similar symptoms been observed with other drugs? = No (HAIRRFUR57=N),
#' then the specify field (HAIRRFUR57OTH) must be blank.
#'
#' @param hair_data HAIRRFU dataset
#' @return Data frame with invalid records
check_HAIRRFU208 <- function(hair_data) {
    message("Running check_HAIRRFU208...")

    req_vars <- c("SIMSX", "SIMSX_OTH")
    if (!all(req_vars %in% names(hair_data))) {
        return(NULL)
    }

    # SAS Logic: if UPCASE(SIMSX) = 'NO' and SIMSX_OTH ne ' ' then output;

    invalid_records <- hair_data %>%
        filter(toupper(SIMSX) == "NO") %>%
        filter(trimws(SIMSX_OTH) != "" & !is.na(SIMSX_OTH)) %>%
        select(SUBJID, SIMSX, SIMSX_OTH)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HAIRRFU208: Found", nrow(invalid_records), "records with inconsistent 'No' specification"))
    }

    return(invalid_records)
}

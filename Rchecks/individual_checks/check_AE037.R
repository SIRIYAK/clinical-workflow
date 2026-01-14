# check_AE037.R
# Check AE037: Serious Fatal Event End Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE037 (FYI2.txt)

library(dplyr)

#' Check AE037: If 'Is the event serious'=YES (AESER=Y) and 'Death'=Yes (AESDTH=Y),
#' then an event end date must be present (AEENDAT != .).
#'
#' @param ae_data AE dataset
#' @return Data frame with invalid records
check_AE037 <- function(ae_data) {
    message("Running check_AE037...")

    req_vars <- c("AESER", "AESDTH") # AEENDAT
    if (!all(req_vars %in% names(ae_data))) {
        return(NULL)
    }

    # Check for date var
    has_date <- "AEENDAT" %in% names(ae_data)

    if (!has_date) {
        # Check components
        if (all(c("AEENDATYY", "AEENDATMO", "AEENDATDD") %in% names(ae_data))) {
            # Logic: If components are missing
            invalid <- ae_data %>%
                filter(toupper(AESER) == "Y", toupper(AESDTH) == "Y") %>%
                filter(is.na(AEENDATYY) & is.na(AEENDATMO) & is.na(AEENDATDD)) %>%
                select(SUBJID, AESER, AESDTH)
        } else {
            return(NULL)
        }
    } else {
        invalid <- ae_data %>%
            filter(toupper(AESER) == "Y", toupper(AESDTH) == "Y") %>%
            filter(is.na(AEENDAT) | as.character(AEENDAT) == "") %>%
            select(SUBJID, AESER, AESDTH, AEENDAT)
    }

    if (exists("invalid") && nrow(invalid) > 0) {
        message(paste("check_AE037: Found", nrow(invalid), "fatal AEs without end date"))
    }

    return(if (exists("invalid")) invalid else NULL)
}

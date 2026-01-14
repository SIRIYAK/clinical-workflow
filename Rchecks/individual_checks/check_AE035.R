# check_AE035.R
# Check AE035: Fatal Outcome Check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE035 (FYI2.txt)

library(dplyr)

#' Check AE035: If 'Is the event serious?'=YES (AESER=Y) and 'Death'=YES (AESDTH=Y),
#' then the Adverse Event Outcome must be 'Fatal' (AEOUT=FATAL).
#'
#' @param ae_data AE dataset
#' @return Data frame with invalid records
check_AE035 <- function(ae_data) {
    message("Running check_AE035...")

    req_vars <- c("AESER", "AESDTH", "AEOUT")
    if (!all(req_vars %in% names(ae_data))) {
        return(NULL)
    }

    invalid <- ae_data %>%
        filter(toupper(AESER) == "Y", toupper(AESDTH) == "Y") %>%
        filter(toupper(trimws(AEOUT)) != "FATAL") %>%
        select(SUBJID, AESER, AESDTH, AEOUT)

    if (nrow(invalid) > 0) {
        message(paste("check_AE035: Found", nrow(invalid), "fatal AEs without Fatal outcome"))
    }

    return(invalid)
}

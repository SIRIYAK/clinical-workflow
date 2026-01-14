# check_AE027.R
# Check AE027: Severity/Seriousness Progression
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE027 (FYI2.txt)

library(dplyr)

#' Check AE027: Events with the same AEGRPID must have a change in Severity
#' or Seriousness in chronologic entries.
#' SAS logic checks adjacent records of same group. If current severity/seriousness
#' == prev severity/seriousness, it flags it.
#'
#' @param ae_data AE dataset
#' @return Data frame with invalid records (duplicate states)
check_AE027 <- function(ae_data) {
    message("Running check_AE027...")

    req_vars <- c("AEGRPID", "AESTDAT", "AESEV", "AESER")

    # Pre-check existence of date or components
    if (!"AESTDAT" %in% names(ae_data)) {
        if (all(c("AESTDATYY", "AESTDATMO", "AESTDATDD") %in% names(ae_data))) {
            ae_data <- ae_data %>% mutate(AESTDAT = as.Date(paste(AESTDATYY, AESTDATMO, AESTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else {
            return(NULL)
        }
    }

    ae_sorted <- ae_data %>%
        filter(!is.na(AEGRPID) & as.character(AEGRPID) != "") %>%
        arrange(SUBJID, AEGRPID, AESTDAT)

    # Lag comparison
    invalid <- ae_sorted %>%
        group_by(SUBJID, AEGRPID) %>%
        filter(n() > 1) %>% # Only groups with potential progression
        mutate(
            PREV_SEV = lag(AESEV),
            PREV_SER = lag(AESER)
        ) %>%
        slice(-1) %>% # Remove first record (no prev)
        filter(AESEV == PREV_SEV & AESER == PREV_SER) %>%
        select(SUBJID, AEGRPID, AESTDAT, AESEV, AESER, PREV_SEV, PREV_SER) %>%
        ungroup()

    if (nrow(invalid) > 0) {
        message(paste("check_AE027: Found", nrow(invalid), "AE records with no change in severity/seriousness"))
    }

    return(invalid)
}

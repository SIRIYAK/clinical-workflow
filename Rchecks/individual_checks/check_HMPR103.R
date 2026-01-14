# check_HMPR103.R
# Check HMPR103: Procedure Performance validation
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR103 (FYI3.txt)

library(dplyr)

#' Check HMPR103: If Yes is selected (PRYN_HMPR=Y), then Was <PRTRT> performed? (PROCCUR) must be completed.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR103 <- function(hmpr_data) {
    message("Running check_HMPR103...")

    # Check vars: PRYN_HMPR, PROCCUR, PRPRESP
    req_vars <- c("PRYN_HMPR", "PROCCUR", "PRPRESP")

    if (!all(req_vars %in% names(hmpr_data))) {
        # Try finding case-insensitive matches or just warn
        warning(paste("check_HMPR103: Missing variables:", paste(req_vars[!req_vars %in% names(hmpr_data)], collapse = ", ")))
        return(NULL)
    }

    # SAS Logic:
    # if UPCASE(PRYN_HMPR) eq "Y" and (UPCASE(PROCCUR) eq " " and UPCASE(PRPRESP) ne "Y");
    # Note: PRPRESP ne "Y" check included in SAS logic.

    invalid_records <- hmpr_data %>%
        filter(toupper(PRYN_HMPR) == "Y") %>%
        # Logic: If Yes, PROCCUR must be 'Y' (or 'N'). If blank, check PRPRESP != 'Y' (Prespecified?)
        # SAS: if UPCASE(PRYN_HMPR) eq "Y" and (UPCASE(PROCCUR) eq " " and UPCASE(PRPRESP) ne "Y");
        filter(
            (trimws(PROCCUR) == "" | is.na(PROCCUR)) &
                (toupper(PRPRESP) != "Y")
        ) %>%
        select(SUBJID, PRYN_HMPR, PROCCUR, PRPRESP)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HMPR103: Found", nrow(invalid_records), "records with missing performance status"))
    }

    return(invalid_records)
}

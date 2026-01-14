# check_HMPR109.R
# Check HMPR109: Dilated bile ducts consistency
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR109 (FYI3.txt)

library(dplyr)

#' Check HMPR109: If Dilated bile ducts is selected (HMPRES1_D)
#' then Dilated Bile Ducts Result (HMPRES5) must be completed.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR109 <- function(hmpr_data) {
    message("Running check_HMPR109...")

    # Required variables: SUBJID, HMPRES1_D, HMPRES5
    req_vars <- c("subjid", "hmpres1_d", "hmpres5")
    missing_vars <- req_vars[!req_vars %in% names(hmpr_data)]

    if (length(missing_vars) > 0) {
        warning(paste("check_HMPR109: Missing variables in HMPR dataset:", paste(missing_vars, collapse = ", ")))
        return(NULL)
    }

    # SAS Logic: if UPCASE(HMPRES1_D) = 'DILATED BILE DUCTS' and missing(HMPRES5) then output;

    invalid_records <- hmpr_data %>%
        filter(toupper(HMPRES1_D) == "DILATED BILE DUCTS") %>%
        filter(is.na(HMPRES5) | trimws(as.character(HMPRES5)) == "") %>%
        select(SUBJID, HMPRES1_D, HMPRES5)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HMPR109: Found", nrow(invalid_records), "records with missing dilation result"))
    }

    return(invalid_records)
}

# check_HMPR107.R
# Check HMPR107: MRE Results check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR107 (FYI3.txt)

library(dplyr)

#' Check HMPR107: If Yes was selected for Was MRE performed? (PROCCUR=Y)
#' and Procedure Name (PRTRT_HMPR) is "MRE_MAGNETIC RESONANCE ELASTOGRAPHY",
#' then MRE results (HMPRES2) and level of fibrosis (HMPRES3) must be completed.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR107 <- function(hmpr_data) {
    message("Running check_HMPR107...")

    # Required vars
    req_vars <- c("PROCCUR", "PRTRT_HMPR", "HMPRES2", "HMPRES3")
    if (!all(req_vars %in% names(hmpr_data))) {
        warning(paste("check_HMPR107: Missing required variables in HMPR dataset:", paste(req_vars[!req_vars %in% names(hmpr_data)], collapse = ", ")))
        return(NULL)
    }

    # SAS Logic:
    # if UPCASE(PROCCUR) eq "Y" and UPCASE(PRTRT_HMPR) eq "MRE_MAGNETIC RESONANCE ELASTOGRAPHY"
    invalid_records <- hmpr_data %>%
        filter(toupper(PROCCUR) == "Y") %>%
        filter(grepl("MRE_MAGNETIC RESONANCE ELASTOGRAPHY", toupper(PRTRT_HMPR), fixed = TRUE)) %>%
        filter(
            (is.na(HMPRES2) | trimws(as.character(HMPRES2)) == "") |
                (is.na(HMPRES3) | trimws(as.character(HMPRES3)) == "")
        ) %>%
        select(SUBJID, PROCCUR, PRTRT_HMPR, HMPRES2, HMPRES3)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HMPR107: Found", nrow(invalid_records), "records with incomplete MRE results"))
    }

    return(invalid_records)
}

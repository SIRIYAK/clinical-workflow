# check_AE017.R
# Check AE017: Event Group vs Dictionary Term
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE017 (FYI2.txt)

library(dplyr)

#' Check AE017: Events with the same AEGRPID must have the same AEDECOD (Dictionary term) across the study.
#' SAS logic: Sort by subjid+aegrpid. Retain first decod. If subsequent decod != first, output.
#' Limits check to within-subject (subjid in sort keys).
#'
#' @param ae_data AE dataset
#' @return Data frame with inconsistent records
check_AE017 <- function(ae_data) {
    message("Running check_AE017...")

    if (!all(c("AEGRPID", "AEDECOD") %in% names(ae_data))) {
        return(NULL)
    }

    # Filter for non-empty groups
    grouped <- ae_data %>%
        filter(!is.na(AEGRPID) & as.character(AEGRPID) != "")

    # Check consistency
    inconsistent <- grouped %>%
        distinct(SUBJID, AEGRPID, AEDECOD) %>%
        group_by(SUBJID, AEGRPID) %>%
        filter(n() > 1) %>% # Multiple DECODs for same GroupID
        ungroup() %>%
        arrange(SUBJID, AEGRPID)

    if (nrow(inconsistent) > 0) {
        message(paste("check_AE017: Found", nrow(inconsistent), "AE Groups with multiple dictionary terms"))
    }

    return(inconsistent)
}

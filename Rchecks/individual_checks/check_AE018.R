# check_AE018.R
# Check AE018: AEDECOD Consistency (PT Term)
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE018 (FYI2.txt)

library(dplyr)

#' Check AE018: AEDECOD (PT Term) must correctly describe adverse event.
#' SAS logic: Distinct SUBJID, PT, LLT. Sort by SUBJID PT.
#' If not (first.PT and last.PT) output.
#' This means: Are there multiple LLTs for the same PT within a subject?
#' Or duplicates?
#' SAS Code: "dummy=compress(catx('',subjid,PT,LLT)); ... nodupkey ... by subjid PT; if not (first.PT and last.PT)"
#' If first.PT != last.PT, it means there is >1 record for that PT group.
#' Meaning: A Subject has the SAME PT mapped to DIFFERENT LLTs?
#' Or just duplicate records?
#' "Objective - AEDECOD (PT Term) must correctly describe adverse event."
#' The SAS code seems to flag if a single Subject-PT combination maps to different LLTs?
#' Let's assume uniqueness check of PT vs LLT within subject.
#'
#' @param ae_data AE dataset
#' @return Data frame with inconsistent records
check_AE018 <- function(ae_data) {
    message("Running check_AE018...")

    # Vars: AELLT, AEDECOD (PT), AETERM
    if (!all(c("AEDECOD", "AELLT") %in% names(ae_data))) {
        return(NULL)
    }

    # Check for multiple LLTs for same PT within subject
    inconsistent <- ae_data %>%
        distinct(SUBJID, AEDECOD, AELLT) %>%
        group_by(SUBJID, AEDECOD) %>%
        filter(n() > 1) %>% # More than 1 LLT for this PT
        ungroup() %>%
        arrange(SUBJID, AEDECOD)

    if (nrow(inconsistent) > 0) {
        message(paste("check_AE018: Found", nrow(inconsistent), "inconsistent PT/LLT mappings"))
    }

    return(inconsistent)
}

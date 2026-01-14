# check_HMPR110.R
# Check HMPR110: Diagnosis for event entry on AE CRF
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR110 (FYI3.txt)

library(dplyr)

#' Check HMPR110: Ensure the diagnosis for any event is entered on the AE CRF.
#' Flags subjects present in HMPR but missing from AE dataset.
#'
#' @param hmpr_data HMPR dataset (e.g., HMPR1001)
#' @param ae_data AE dataset (e.g., AE6001/AE3001)
#' @return Data frame with missing diagnosis subjects
check_HMPR110 <- function(hmpr_data, ae_data) {
    message("Running check_HMPR110...")

    # Logic: Subjects in HMPR but NOT in AE (anti-join).
    # But wait, SAS "where b.subjid is null" from left join hmpr (a) ae (b).
    # This implies checking if subject exists in AE at all?
    # Or specific event diagnosis linkage?
    # "Objective - If an event diagnosis is indicated check that it is entered on the AE CRF."
    # SAS Code: "select distinct a.*, b.AETERM from &indsn1. a left join &indsn2. b on a.subjid=b.subjid where b.subjid is null;"
    # If indsn1 is HMPR and indsn2 is AE. This checks if a subject in HMPR has ANY records in AE.
    # If b.subjid is null, it means no AE record for this subject.
    # This seems to imply if you have HMPR data, you MUST have AE data.

    # Simplified check as per SAS logic:

    subjects_in_hmpr <- hmpr_data %>% distinct(SUBJID)
    subjects_in_ae <- ae_data %>% distinct(SUBJID)

    missing_from_ae <- subjects_in_hmpr %>%
        anti_join(subjects_in_ae, by = "SUBJID")

    if (nrow(missing_from_ae) > 0) {
        message(paste("check_HMPR110: Found", nrow(missing_from_ae), "subjects in HMPR but missing from AE"))
    }

    return(missing_from_ae)
}

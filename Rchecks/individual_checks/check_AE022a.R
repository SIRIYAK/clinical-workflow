# check_AE022a.R
# Check AE022a: Event End vs Disposition Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE022a (FYI2.txt)

library(dplyr)

#' Check AE022a: Event End Date must be <= subject's final disposition.
#'
#' @param ae_data AE dataset
#' @param ds_data DS dataset
#' @return Data frame with invalid records
check_AE022a <- function(ae_data, ds_data) {
    message("Running check_AE022a...")

    if (!"AEENDAT" %in% names(ae_data)) {
        return(NULL)
    }
    # DS: DSSTDAT (implied date) for "STUDY DISPOSITION"

    # Get Final Disposition Date
    ds_final <- ds_data %>%
        filter(toupper(DSSCAT) == "STUDY DISPOSITION") %>%
        arrange(SUBJID, desc(DSSTDAT)) %>%
        group_by(SUBJID) %>%
        slice(1) %>%
        ungroup() %>%
        select(SUBJID, DS_END_DATE = DSSTDAT)

    invalid <- ae_data %>%
        filter(!is.na(AEENDAT)) %>%
        inner_join(ds_final, by = "SUBJID") %>%
        filter(!is.na(DS_END_DATE)) %>%
        filter(AEENDAT > DS_END_DATE) %>%
        select(SUBJID, AEENDAT, DS_END_DATE)

    if (nrow(invalid) > 0) {
        message(paste("check_AE022a: Found", nrow(invalid), "events ending after disposition"))
    }

    return(invalid)
}

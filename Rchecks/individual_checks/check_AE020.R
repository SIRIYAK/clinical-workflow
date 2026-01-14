# check_AE020.R
# Check AE020: Event Start Date vs Informed Consent
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE020 (FYI2.txt)

library(dplyr)

#' Check AE020: If Event Start Date is < the informed consent date,
#' then the event should not be recorded on the Study Adverse Events CRF.
#'
#' @param ae_data AE dataset
#' @param ds_data DS dataset (DS2001 - IC)
#' @return Data frame with invalid records
check_AE020 <- function(ae_data, ds_data) {
    message("Running check_AE020...")

    if (!"AESTDAT" %in% names(ae_data)) {
        return(NULL)
    }

    # Identify IC Date
    # SAS uses DS2001 where DSSCAT_IC='STUDY' and vars DSSTDAT_IC...
    # We will look for DSSTDAT_IC or construct it, or look for standard DSSTDAT with filter.

    ic_data <- ds_data
    has_ic_vars <- all(c("DSSTDAT_ICYY", "DSSTDAT_ICMO", "DSSTDAT_ICDD") %in% names(ds_data))

    if (has_ic_vars) {
        ic_data <- ic_data %>%
            mutate(IC_DATE = as.Date(paste(DSSTDAT_ICYY, DSSTDAT_ICMO, DSSTDAT_ICDD, sep = "-"), format = "%Y-%m-%d"))
    } else if ("DSSTDAT" %in% names(ds_data)) {
        ic_data <- ic_data %>% rename(IC_DATE = DSSTDAT)
    } else {
        return(NULL) # Cannot establishing IC date
    }

    # Filter for IC records if relevant variable exists
    if ("DSSCAT_IC" %in% names(ic_data)) {
        ic_data <- ic_data %>% filter(toupper(DSSCAT_IC) == "STUDY")
    }

    # Take first IC date per subject
    ic_dates <- ic_data %>%
        arrange(SUBJID, IC_DATE) %>%
        group_by(SUBJID) %>%
        slice(1) %>%
        ungroup() %>%
        select(SUBJID, IC_DATE)

    invalid <- ae_data %>%
        filter(!is.na(AESTDAT)) %>%
        left_join(ic_dates, by = "SUBJID") %>%
        filter(!is.na(IC_DATE)) %>%
        filter(AESTDAT < IC_DATE) %>%
        select(SUBJID, AESTDAT, IC_DATE)

    if (nrow(invalid) > 0) {
        message(paste("check_AE020: Found", nrow(invalid), "AEs starting before informed consent"))
    }

    return(invalid)
}

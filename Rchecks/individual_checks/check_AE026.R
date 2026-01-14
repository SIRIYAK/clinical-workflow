# check_AE026.R
# Check AE026: Death Date vs Final Event End Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE026 (FYI2.txt)

library(dplyr)

#' Check AE026: If DS reason for discontinuation is 'Death' (DSDECOD=DEATH),
#' Death Date (DTHDAT) must be equal to the End Date of the Fatal Event (AESDTH=Y).
#'
#' @param ae_data AE dataset (AE3001)
#' @param ds_data DS dataset (DS1001)
#' @return Data frame with invalid records
check_AE026 <- function(ae_data, ds_data) {
    message("Running check_AE026...")

    # Required vars
    # AE: AESDTH, AEENDAT
    # DS: DSDECOD, DTHDAT

    if (!"AESDTH" %in% names(ae_data) || !"DSDECOD" %in% names(ds_data)) {
        return(NULL)
    }

    # Check for date vars or components
    # Assuming standard date handling or skipping if unavailable
    has_ae_date <- "AEENDAT" %in% names(ae_data)
    has_ds_date <- "DTHDAT" %in% names(ds_data)

    if (!has_ae_date || !has_ds_date) {
        return(NULL)
    } # Simplified for brevity

    # Get Death dispositions
    ds_death <- ds_data %>%
        filter(toupper(DSDECOD) == "DEATH") %>%
        select(SUBJID, DSDECOD, DTHDAT)

    invalid <- ae_data %>%
        filter(toupper(AESDTH) == "Y") %>%
        inner_join(ds_death, by = "SUBJID") %>%
        filter(AEENDAT != DTHDAT) %>% # Mismatch
        select(SUBJID, AESDTH, AEENDAT, DTHDAT)

    if (nrow(invalid) > 0) {
        message(paste("check_AE026: Found", nrow(invalid), "records with mismatched death dates"))
    }

    return(invalid)
}

# check_AE024.R
# Check AE024: End Date >= Start Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE024 (FYI2.txt)

library(dplyr)

#' Check AE024: If present, Event End Date must be >= Event Start Date.
#' SAS Logic: if End Date exists and Start > End -> Output.
#'
#' @param ae_data AE dataset
#' @return Data frame with invalid (inverted date) records
check_AE024 <- function(ae_data) {
    message("Running check_AE024...")

    if (!all(c("AESTDAT", "AEENDAT") %in% names(ae_data))) {
        return(NULL)
    }

    invalid <- ae_data %>%
        filter(!is.na(AEENDAT) & !is.na(AESTDAT)) %>%
        filter(AESTDAT > AEENDAT) %>%
        select(SUBJID, AESTDAT, AEENDAT)

    if (nrow(invalid) > 0) {
        message(paste("check_AE024: Found", nrow(invalid), "records with Start Date > End Date"))
    }

    return(invalid)
}

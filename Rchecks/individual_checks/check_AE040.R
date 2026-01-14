# check_AE040.R
# Check AE040: Related AE Listing
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE040 (FYI2.txt)

library(dplyr)

#' Check AE040: If Related to Study Treatment 'Yes' (AEREL=Y),
#' listing dump (originally logic check, now dump).
#'
#' @param ae_data AE dataset
#' @return Data frame with related AEs
check_AE040 <- function(ae_data) {
    message("Running check_AE040...")

    if (!"AEREL" %in% names(ae_data)) {
        return(NULL)
    }

    # SAS Logic: if upcase(strip(AEREL))="Y";

    related_aes <- ae_data %>%
        filter(toupper(trimws(AEREL)) == "Y") %>%
        select(any_of(c("SUBJID", "AEREL", "AESTDAT", "AETERM", "AEDECOD", "AEGRPID")))

    if (nrow(related_aes) > 0) {
        message(paste("check_AE040: Found", nrow(related_aes), "related AEs (Listing)"))
    }

    return(related_aes)
}

# check_GEN008.R
# Check GEN008: Informed Consent Date vs Birth Year
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_GEN008 (FYI3.txt)

library(dplyr)
library(lubridate)

#' Check GEN008: Year in the <Informed Consent> Date must be >= Year Birth.
#' (Using CMSTDAT based on macro code, despite description usually implying DS or ICM)
#' Note: Macro GEN008 input vars are CMSTDAT and BRTHYR.
#'
#' @param cm_data CM (Concomitant Medications) dataset or dataset containing CMSTDAT
#' @param dm_data DM (Demographics) dataset containing BRTHYR
#' @return Data frame with invalid records
check_GEN008 <- function(cm_data, dm_data) {
    message("Running check_GEN008...")

    # Check required variables
    # Note: SAS macro specifically checks CMSTDAT in indsn1 and BRTHYR in indsn2
    if (!all(c("subjid", "cmstdat") %in% names(cm_data))) {
        warning("check_GEN008: Missing variables in CM dataset")
        return(NULL)
    }

    if (!all(c("subjid", "brthyr") %in% names(dm_data))) {
        warning("check_GEN008: Missing variables in DM dataset")
        return(NULL)
    }

    # Join Data
    merged_data <- cm_data %>%
        inner_join(dm_data, by = "subjid")

    # Check Logic: year(CMSTDAT) < brthyr
    # Handle Date conversion if needed. Assuming CMSTDAT is Date or convertable.
    # SAS macro logic: where year(CMSTDAT) < brthyr and CMSTDAT ne . and brthyr ne .;

    invalid_records <- merged_data %>%
        filter(!is.na(cmstdat), !is.na(brthyr)) %>%
        mutate(cm_year = year(cmstdat)) %>%
        filter(cm_year < brthyr) %>%
        distinct(subjid, cmstdat, brthyr, .keep_all = TRUE)

    if (nrow(invalid_records) > 0) {
        message(paste("check_GEN008: Found", nrow(invalid_records), "records with Year < Birth Year"))
    }

    return(invalid_records)
}

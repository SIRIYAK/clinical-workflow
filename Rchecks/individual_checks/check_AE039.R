# check_AE039.R
# Check AE039: AE Start Date vs Treatment Start Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE039 (FYI2.txt)

library(dplyr)
library(lubridate)

#' Check AE039: If Event related (AEREL=Y) AND Treatment Taken (ECOCCUR=Y),
#' the event start date must be >= treatment start date.
#' SAS logic: ae_start_date < ec_start_date (Invalid condition).
#'
#' @param ae_data AE dataset
#' @param ec_data EC (Exposure/Treatment) dataset
#' @return Data frame with invalid records
check_AE039 <- function(ae_data, ec_data) {
    message("Running check_AE039...")

    # Check vars
    # AE: AEREL, AESTDAT...
    # EC: ECOCCUR, ECSTDAT...

    if (!"AEREL" %in% names(ae_data) || !"ECOCCUR" %in% names(ec_data)) {
        return(NULL)
    }

    # SAS logic grabs FIRST EC record per subject.
    # "if first.subjid then output;" from EC dataset sorted by ec_start_date.

    # Preprocess dates if needed (Assuming standard 'AESTDAT'/'ECSTDAT' exist or using components)
    # Skipping component reconstruction for brevity, assume standardized 'AESTDAT'/'ECSTDAT' present or added by utils.
    # If not present, this check requires them.

    if (!"ECSTDAT" %in% names(ec_data)) {
        # Try to construct from components if available
        if (all(c("ECSTDATYY", "ECSTDATMO", "ECSTDATDD") %in% names(ec_data))) {
            ec_data <- ec_data %>% mutate(ECSTDAT = as.Date(paste(ECSTDATYY, ECSTDATMO, ECSTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else {
            return(NULL)
        }
    }

    if (!"AESTDAT" %in% names(ae_data)) {
        if (all(c("AESTDATYY", "AESTDATMO", "AESTDATDD") %in% names(ae_data))) {
            ae_data <- ae_data %>% mutate(AESTDAT = as.Date(paste(AESTDATYY, AESTDATMO, AESTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else {
            return(NULL)
        }
    }


    first_ec <- ec_data %>%
        filter(!is.na(ECSTDAT)) %>%
        arrange(SUBJID, ECSTDAT) %>%
        group_by(SUBJID) %>%
        slice(1) %>%
        ungroup() %>%
        select(SUBJID, EC_START_DATE = ECSTDAT, ECOCCUR)

    invalid <- ae_data %>%
        filter(toupper(trimws(AEREL)) == "Y") %>%
        left_join(first_ec, by = "SUBJID") %>%
        filter(toupper(trimws(ECOCCUR)) == "Y") %>%
        filter(AESTDAT < EC_START_DATE) %>%
        select(SUBJID, AEREL, AESTDAT, EC_START_DATE)

    if (nrow(invalid) > 0) {
        message(paste("check_AE039: Found", nrow(invalid), "related AEs starting before treatment"))
    }

    return(invalid)
}

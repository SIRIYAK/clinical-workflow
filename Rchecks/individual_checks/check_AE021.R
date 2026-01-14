# check_AE021.R
# Check AE021: AE vs Medical History Duplication
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE021 (FYI2.txt)

library(dplyr)

#' Check AE021: If identical term (LLTID/DICTVER) recorded on AE and MH CRFs,
#' start dates must not match.
#' SAS logic uses inner join on subjid, lltid, dictver.
#'
#' @param ae_data AE dataset
#' @param mh_data MH dataset
#' @return Data frame with duplicate AE/MH records
check_AE021 <- function(ae_data, mh_data) {
    message("Running check_AE021...")

    req_vars <- c("LLTID", "DICTVER", "AESTDAT") # MH: MHSTDAT
    if (!all(req_vars %in% names(ae_data))) {
        return(NULL)
    }

    # Preprocess MH dates if needed
    if (!"MHSTDAT" %in% names(mh_data)) {
        if (all(c("MHSTDATYY", "MHSTDATMO", "MHSTDATDD") %in% names(mh_data))) {
            mh_data <- mh_data %>% mutate(MHSTDAT = as.Date(paste(MHSTDATYY, MHSTDATMO, MHSTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else {
            return(NULL)
        }
    }

    invalid <- ae_data %>%
        inner_join(mh_data, by = c("SUBJID", "LLTID", "DICTVER"), suffix = c(".AE", ".MH")) %>%
        filter(!is.na(AESTDAT) & !is.na(MHSTDAT)) %>%
        filter(AESTDAT == MHSTDAT) %>%
        select(SUBJID, LLTID, AESTDAT, MHSTDAT)

    if (nrow(invalid) > 0) {
        message(paste("check_AE021: Found", nrow(invalid), "matching AE/MH records"))
    }

    return(invalid)
}

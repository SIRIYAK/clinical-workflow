# check_AE036.R
# Check AE036: Death Status Concordance
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE036 (FYI2.txt)

library(dplyr)
library(lubridate)

#' Check AE036: If Death = Yes (AESDTH=Y), then the subject status on last
#' disposition form should be death (DSDECOD=DEATH).
#'
#' @param ae_data AE dataset
#' @param ds_data DS dataset
#' @return Data frame with discordant records
check_AE036 <- function(ae_data, ds_data) {
    message("Running check_AE036...")

    if (!"AESDTH" %in% names(ae_data)) {
        return(NULL)
    }

    if (!all(c("DSDECOD", "DSSTDAT") %in% names(ds_data))) {
        # Handles components if main date missing
        if (all(c("DSDECOD", "DSSTDATYY", "DSSTDATMO", "DSSTDATDD") %in% names(ds_data))) {
            ds_data <- ds_data %>% mutate(DSSTDAT = as.Date(paste(DSSTDATYY, DSSTDATMO, DSSTDATDD, sep = "-"), format = "%Y-%m-%d"))
        } else {
            # If DS data crucial vars missing, skip
            return(NULL)
        }
    }

    # Get last DS record per subject
    last_ds <- ds_data %>%
        arrange(SUBJID, DSSTDAT) %>%
        group_by(SUBJID) %>%
        slice(n()) %>% # Get last
        ungroup() %>%
        select(SUBJID, DSDECOD, DS_START_DATE = DSSTDAT)

    invalid <- ae_data %>%
        filter(toupper(AESDTH) == "Y") %>%
        distinct(SUBJID, AESDTH) %>% # AE level: just need to know if ANY AE caused death?
        # SAS logic: joins AE (with aesdth='Y') to last DS.
        left_join(last_ds, by = "SUBJID") %>%
        filter(toupper(DSDECOD) != "DEATH") %>%
        select(SUBJID, AESDTH, DSDECOD, DS_START_DATE)

    if (nrow(invalid) > 0) {
        message(paste("check_AE036: Found", nrow(invalid), "subjects with Death AE but no Death disposition"))
    }

    return(invalid)
}

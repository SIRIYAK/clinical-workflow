# check_EX103.R
# Check EX103: Dose adjustment due to AE check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_EX103 (FYI3.txt)

library(dplyr)
library(lubridate)

#' Check EX103: If reason for dose adjustment is adverse event,
#' ensure treatment start date is greater than the adverse event start date
#' for which the treatment was adjusted.
#'
#' @param ex_data EX (Exposure) dataset
#' @param ae_data AE (Adverse Events) dataset
#' @return Data frame with invalid records
check_EX103 <- function(ex_data, ae_data) {
    message("Running check_EX103...")

    # Check required variables
    if (!all(c("subjid", "exadj", "exstdat", "aegrpid_relrec4") %in% names(ex_data))) {
        warning("check_EX103: Missing variables in EX dataset")
        return(NULL)
    }

    if (!all(c("subjid", "aestdat", "aegrpid_relrec") %in% names(ae_data))) {
        warning("check_EX103: Missing variables in AE dataset")
        return(NULL)
    }

    # Filter EX for dose adjustment due to AE
    ex_filtered <- ex_data %>%
        filter(toupper(exadj) == "ADVERSE EVENT")

    if (nrow(ex_filtered) == 0) {
        return(NULL) # No records to check
    }

    # Join with AE data on SUBJID and Group ID
    # Note: SAS macro used: a.subjid=b.subjid and a.AEGRPID_RELREC4 = b.AEGRPID_RELREC

    invalid_records <- ex_filtered %>%
        inner_join(ae_data,
            by = c(
                "subjid" = "subjid",
                "aegrpid_relrec4" = "aegrpid_relrec"
            ),
            suffix = c(".ex", ".ae")
        ) %>%
        filter(exstdat <= aestdat) %>% # Invalid condition: Treatment Start <= AE Start
        select(subjid, exstdat, aestdat, exadj, aegrpid_relrec4)

    if (nrow(invalid_records) > 0) {
        message(paste("check_EX103: Found", nrow(invalid_records), "invalid records"))
    }

    return(invalid_records)
}

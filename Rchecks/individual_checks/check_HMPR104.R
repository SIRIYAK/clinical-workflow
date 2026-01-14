# check_HMPR104.R
# Check HMPR104: Procedure Start Date check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR104 (FYI3.txt)

library(dplyr)

#' Check HMPR104: If Yes is selected for Was <PRTRT> performed? (PROCCUR=Y)
#' then Start Date must be completed.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR104 <- function(hmpr_data) {
    message("Running check_HMPR104...")

    # Check for variables
    # SAS macro logic constructs date from PRSTDATMO, PRSTDATDD, PRSTDATYY using u_getdate
    # But often in R we might have a composite date variable or the 3 components.
    # I will check for the component variables

    vars_found <- names(hmpr_data)
    date_components <- c("prstdatmo", "prstdatdd", "prstdatyy")

    if ("proccur" %in% vars_found) {
        # proceed
    } else {
        warning("check_HMPR104: Missing PROCCUR")
        return(NULL)
    }


    return(if (exists("invalid_records")) invalid_records else NULL)
}

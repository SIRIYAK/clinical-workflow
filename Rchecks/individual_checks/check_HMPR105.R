# check_HMPR105.R
# Check HMPR105: 'Other' specification check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR105 (FYI3.txt)

library(dplyr)

#' Check HMPR105: If 'Other' was selected (HMPRES1_L),
#' then specify field (HMPRES1_LOTH) should not be blank.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR105 <- function(hmpr_data) {
    message("Running check_HMPR105...")

    req_vars <- c("HMPRES1_L", "HMPRES1_LOTH")
    if (!all(req_vars %in% names(hmpr_data))) {
        return(NULL)
    }

    # SAS Logic: if UPCASE(HMPRES1_L) = 'OTHER' and HMPRES1_LOTH = ' ' then output;
}

# check_AE025.R
# Check AE025: Disposition Status vs Event End Date
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_AE025 (FYI2.txt)

library(dplyr)

#' Check AE025: If Subject's status on Disposition CRF is present (Ended due to AE),
#' then event end date must be present or AEONGO=YES (here NO checked for logic).
#' SAS Logic: where a.DSDECOD='ADVERSE EVENT' and ae_end_date =. and AEONGO='N';
#'
#' @param ae_data AE dataset
#' @param ds_data DS dataset
#' @return Data frame with invalid records
check_AE025 <- function(ae_data, ds_data) {
    message("Running check_AE025...")

    req_vars <- c("SUBJID", "AEONGO", "DSDECOD")
    # Date handling implied

    # Get DS Discontinued due to AE
    ds_ae <- ds_data %>%
        filter(toupper(DSDECOD) == "ADVERSE EVENT") %>%
        select(SUBJID, DSDECOD)

    invalid <- ae_data %>%
        filter(toupper(AEONGO) == "N") %>%
        filter(is.na(AEENDAT)) %>% # Assuming AEENDAT constructed or exists
        inner_join(ds_ae, by = "SUBJID") %>%
        select(SUBJID, AEONGO, AEENDAT, DSDECOD)

    if (nrow(invalid) > 0) {
        message(paste("check_AE025: Found", nrow(invalid), "AE dropouts missing end date"))
    }

    return(invalid)
}

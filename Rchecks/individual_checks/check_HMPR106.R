# check_HMPR106.R
# Check HMPR106: Procedure Performed Result Check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HMPR106 (FYI3.txt)

library(dplyr)
library(tidyr)

#' Check HMPR106: If Yes was selected for Was <PRTRT> performed? (PROCCUR=Y)
#' then at least one result of the test must be selected.
#'
#' Checks variables: HMPRES1_A through HMPRES1_L, HMPRES2, HMPRES3, HMPRES4, HMPRES5.
#'
#' @param hmpr_data HMPR dataset
#' @return Data frame with invalid records
check_HMPR106 <- function(hmpr_data) {
    message("Running check_HMPR106...")

    # Required vars (minimal set to run logic)
    # SAS macro lists HMPRES1_A ... L, HMPRES2...5

    # Lets check for at least ONE result column existence
    res_cols <- c(paste0("HMPRES1_", LETTERS[1:12]), "HMPRES2", "HMPRES3", "HMPRES4", "HMPRES5")
    existing_res_cols <- intersect(names(hmpr_data), res_cols)

    if (length(existing_res_cols) == 0) {
        warning("check_HMPR106: No result variables found in HMPR dataset")
        return(NULL)
    }

    invalid_records <- hmpr_data %>%
        filter(toupper(PROCCUR) == "Y") %>%
        # Filter where ALL existing result columns are NA or blank
        filter(if_all(all_of(existing_res_cols), ~ is.na(.) | trimws(as.character(.)) == "")) %>%
        select(SUBJID, PROCCUR, any_of("PRTRT_HMPR"))

    if (nrow(invalid_records) > 0) {
        message(paste("check_HMPR106: Found", nrow(invalid_records), "records with performed procedure but no results"))
    }

    return(invalid_records)
}

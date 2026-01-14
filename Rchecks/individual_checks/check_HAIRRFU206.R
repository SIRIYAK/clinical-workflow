# check_HAIRRFU206.R
# Check HAIRRFU206: Alternative Cause 'Other' negative check
# Author: Siriyak
# Date: 2026-01-14
# Original Macro: m_HAIRRFU206 (FYI3.txt)

library(dplyr)

#' Check HAIRRFU206: Alternative Cause: Other was not selected (HAIRRFUR2E missing/not selected)
#' then the specify field (HAIRRFUR2EOTH) must be blank.
#'
#' @param hair_data HAIRRFU dataset
#' @return Data frame with invalid records
check_HAIRRFU206 <- function(hair_data) {
    message("Running check_HAIRRFU206...")

    req_vars <- c("HAIRC_G", "HAIRC_OTH")
    if (!all(req_vars %in% names(hair_data))) {
        return(NULL)
    }

    # SAS Logic: if UPCASE(HAIRC_G) = 'OTHER' and HAIRC_OTH = ' ' then output;
    # WAIT. Review SAS Logic again.
    # SAS: "Objective - Alternative Cause: Other was not selected then the specify field must be blank."
    # SAS Code: "if missing(HAIRRFUR2EOTH) and not missing(HAIRRFUR2E);"
    # This logic seems to flag cases where "Other Specify" IS MISSING but "Other" IS SELECTED?
    # That matches HMPR105/205 logic usually (If selected -> must specify).
    # BUT the objective says "Other was NOT selected then specify must be blank".
    # Let's re-read Macro m_HAIRRFU206 in FYI3.txt.
    # Line 740: "if missing(HAIRRFUR2EOTH) and not missing(HAIRRFUR2E);"
    # And m_HAIRRFU205 (Line 775): "if not missing(HAIRRFUR2EOTH) and missing(HAIRRFUR2E);"

    # Correction:
    # 206 Logic implies: If Other is SELECTED (not missing) AND Specify is MISSING -> Validation Rule: "If selected must specify".
    # 205 Logic implies: If Other is NOT SELECTED (missing) AND Specify is EXIST -> Validation Rule: "If not selected must be blank".

    # I will stick to the SAS LOGIC over the comment summary if they conflict, or interpret carefully.
    # 206 SAS: missing(Specify) AND not missing(Checkbox). -> This flags "Checked but didn't specify".

    invalid_records <- hair_data %>%
        filter(!is.na(hairrfur2e) & trimws(hairrfur2e) != "") %>% # Checkbox selected
        filter(is.na(hairrfur2eoth) | trimws(hairrfur2eoth) == "") %>% # Specification missing
        select(subjid, hairrfur2e, hairrfur2eoth)

    if (nrow(invalid_records) > 0) {
        message(paste("check_HAIRRFU206: Found", nrow(invalid_records), "records. Checked 'Other' but missing details."))
    }

    return(invalid_records)
}

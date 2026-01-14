# =============================================================================
# Safety Reporting Automation Module
# Author: Siriyak
# Description: Automates safety reporting workflows (SUSAR, CIOMS).
# =============================================================================

library(dplyr)
source("utils.R") # For date helpers if needed

#' Identify Potential SUSARs
#' @param ae_data Adverse Event dataframe
#' @param sae_flag_var Variable name for SAE flag (default "AESER")
#' @param related_var Variable name for Causality (default "AEREL")
#' @return Data frame of potential SUSARs
identify_susar <- function(ae_data, sae_flag_var = "AESER", related_var = "AEREL") {
    # Normalize inputs
    names(ae_data) <- toupper(names(ae_data))
    sae_flag_var <- toupper(sae_flag_var)
    related_var <- toupper(related_var)

    if (!sae_flag_var %in% names(ae_data)) {
        stop(paste("SAE Flag variable", sae_flag_var, "not found."))
    }

    # Filter for Serious AEs
    saes <- ae_data %>%
        filter(!!sym(sae_flag_var) == "Y")

    # Filter for Related (Possible, Probable, etc.)
    # Assuming standard CDISC codelist: RELATED, NOT RELATED or similar
    # Adjust logic based on actual data values
    related_saes <- saes %>%
        filter(grepl("RELATED|POSSIBLE|PROBABLE|DEFINITE", !!sym(related_var), ignore.case = TRUE))

    # Unexpectedness usually requires specific medical review or reference to Investigator Brochure (IB)
    # Here we conservatively flag ALL Related SAEs as "Potential SUSAR" for review

    susars <- related_saes %>%
        mutate(
            Review_Status = "Pending Medical Review",
            Report_Due_Date = as.Date(AESTDTC) + 7 # 7-day rule for fatal/life-threatening
        ) %>%
        select(USUBJID, AETERM, AESTDTC, !!sym(sae_flag_var), !!sym(related_var), Review_Status, Report_Due_Date)

    return(susars)
}

#' Generate Safety Summary Table
#' @param ae_data Adverse Event dataframe
#' @return Data frame summary
generate_safety_summary <- function(ae_data) {
    names(ae_data) <- toupper(names(ae_data))

    summary <- ae_data %>%
        summarise(
            Total_AEs = n(),
            Serious_AEs = sum(AESER == "Y", na.rm = TRUE),
            Severe_AEs = sum(AESEV == "SEVERE" | AESEV == "GRADE 3", na.rm = TRUE),
            Discontinuations = sum(AEACN == "DRUG WITHDRAWN", na.rm = TRUE),
            Deaths = sum(AEOUT == "FATAL", na.rm = TRUE)
        )

    return(summary)
}

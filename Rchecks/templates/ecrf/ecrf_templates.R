# =============================================================================
# eCRF Design Templates Module
# Author: Siriyak
# Description: Standardized templates for electronic Case Report Forms.
# =============================================================================

library(dplyr)

#' Get Demographics (DM) eCRF Template
#' @return Data frame definition
get_template_demog <- function() {
    data.frame(
        Field_Label = c("Subject ID", "Date of Birth", "Sex", "Race", "Ethnicity", "Date of Informed Consent"),
        Variable_Name = c("SUBJID", "BRTHDTC", "SEX", "RACE", "ETHNIC", "RFICDTC"),
        Format = c("Text", "Date (DD-MON-YYYY)", "Codelist (Male/Female)", "Codelist", "Codelist", "Date"),
        Mandatory = c("Yes", "Yes", "Yes", "Yes", "Yes", "Yes"),
        stringsAsFactors = FALSE
    )
}

#' Get Vital Signs (VS) eCRF Template
#' @return Data frame definition
get_template_vitals <- function() {
    data.frame(
        Field_Label = c("Visit Date", "Visit Name", "Systolic BP", "Diastolic BP", "Heart Rate", "Weight", "Height"),
        Variable_Name = c("VSDTC", "VISIT", "SYSBP", "DIABP", "PULSE", "WEIGHT", "HEIGHT"),
        Format = c("Date", "Text", "Number (mmHg)", "Number (mmHg)", "Number (bpm)", "Number (kg)", "Number (cm)"),
        Mandatory = c("Yes", "Yes", "Yes", "Yes", "Yes", "Yes", "No"),
        stringsAsFactors = FALSE
    )
}

#' Get Adverse Events (AE) eCRF Template
#' @return Data frame definition
get_template_ae <- function() {
    data.frame(
        Field_Label = c("AE Term", "Start Date", "End Date", "Severity", "Serious?", "Relationship", "Outcome", "Action Taken"),
        Variable_Name = c("AETERM", "AESTDTC", "AEENDTC", "AESEV", "AESER", "AEREL", "AEOUT", "AEACN"),
        Format = c("Free Text", "Date", "Date", "Codelist (Mild/Mod/Sev)", "Yes/No", "Codelist", "Codelist", "Codelist"),
        Mandatory = c("Yes", "Yes", "No", "Yes", "Yes", "Yes", "No", "Yes"),
        stringsAsFactors = FALSE
    )
}

#' Export Template to Excel
#' @param template_type "DM", "VS", or "AE"
#' @param output_file Path to save
export_ecrf_template <- function(template_type = "DM", output_file) {
    if (template_type == "DM") {
        df <- get_template_demog()
    } else if (template_type == "VS") {
        df <- get_template_vitals()
    } else if (template_type == "AE") {
        df <- get_template_ae()
    } else {
        stop("Unknown template type")
    }

    openxlsx::write.xlsx(df, output_file)
    message(paste("Template exported to", output_file))
}

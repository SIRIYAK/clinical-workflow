# =============================================================================
# Data Transfer Specifications (DTS) Module
# Author: Siriyak
# Description: Generates Data Transfer Specifications from dataset metadata
#              and verifies dataset compliance against specs.
# =============================================================================

library(dplyr)
library(openxlsx)

#' Generate DTS Skeleton from Dataset
#' @param data A data frame or tibble
#' @param domain_name Character string for the domain (e.g., "AE")
#' @return A data frame containing the specification skeleton
generate_dts_skeleton <- function(data, domain_name) {
    if (missing(data) || is.null(data)) {
        return(NULL)
    }

    # Extract metadata mapping
    spec <- data.frame(
        Domain = domain_name,
        Variable = names(data),
        Label = NA,
        Type = sapply(data, function(x) class(x)[1]),
        Length = NA,
        Format = NA,
        Mandatory = "No",
        Codelist = NA,
        Derivation_Logic = NA,
        stringsAsFactors = FALSE
    )

    # Try to extract labels if present (haven/sas7bdat attributes)
    for (i in seq_along(spec$Variable)) {
        var_name <- spec$Variable[i]
        lbl <- attr(data[[var_name]], "label")
        if (!is.null(lbl)) spec$Label[i] <- lbl

        # Approximate length for characters
        if (is.character(data[[var_name]])) {
            max_len <- max(nchar(as.character(data[[var_name]])), na.rm = TRUE)
            spec$Length[i] <- ifelse(is.infinite(max_len), 200, max_len)
        }
    }

    return(spec)
}

#' Export DTS to Excel
#' @param dts_list A list of DTS data frames (one per domain)
#' @param output_path File path for the output Excel file
export_dts <- function(dts_list, output_path) {
    wb <- createWorkbook()

    for (name in names(dts_list)) {
        addWorksheet(wb, name)
        writeData(wb, name, dts_list[[name]])
        setColWidths(wb, name, cols = 1:9, widths = "auto")
    }

    saveWorkbook(wb, output_path, overwrite = TRUE)
    message(paste("DTS exported to:", output_path))
}

#' Compare Data against DTS
#' @param data Actual dataset
#' @param dts_spec DTS data frame for checking
#' @return List of discrepancies
check_dts_compliance <- function(data, dts_spec) {
    issues <- list()

    # Check 1: Missing Variables
    req_vars <- dts_spec %>%
        filter(Mandatory == "Yes") %>%
        pull(Variable)
    missing <- setdiff(req_vars, names(data))
    if (length(missing) > 0) {
        issues$missing_vars <- paste("Missing mandatory variables:", paste(missing, collapse = ", "))
    }

    # Check 2: Type Mismatches
    common <- intersect(names(data), dts_spec$Variable)
    type_mismatch <- c()
    for (var in common) {
        expected <- dts_spec %>%
            filter(Variable == var) %>%
            pull(Type)
        actual <- class(data[[var]])[1]
        # Basic mapping logic (simplistic)
        if (grepl("character", expected, ignore.case = TRUE) && !is.character(data[[var]])) {
            type_mismatch <- c(type_mismatch, var)
        }
    }
    if (length(type_mismatch) > 0) {
        issues$type_mismatch <- paste("Type mismatch:", paste(type_mismatch, collapse = ", "))
    }

    return(issues)
}

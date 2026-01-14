# =============================================================================
# Validate Datasets Against CDISC Standards
# Author: Siriyak
# Description: Compares local SAS datasets against cached CDISC specifications.
# =============================================================================

source("config.R")
source("utils.R")

library(haven)
library(dplyr)
library(openxlsx)

#' Load Cached Standard
#' @param version_name Name of the standard (e.g., "sdtmig-3-2")
#' @return Data frame of standard or NULL
load_standard <- function(version_name) {
    path <- file.path(CDISC_CACHE_DIR, paste0(version_name, ".rds"))
    if (file.exists(path)) {
        return(readRDS(path))
    } else {
        log_message(paste("Standard not found in cache:", path), level = "WARNING")
        return(NULL)
    }
}

#' Validate Single Dataset
#' @param data Local data frame
#' @param ds_name Dataset name (e.g. "AE")
#' @param spec Standard specification data frame
#' @return Data frame of issues
validate_dataset <- function(data, ds_name, spec) {
    # Filter spec for this domain
    domain_spec <- spec %>% filter(Domain == ds_name)

    if (nrow(domain_spec) == 0) {
        return(data.frame(
            Dataset = ds_name,
            Variable = NA,
            Issue = "Domain not found in standard",
            Severity = "Warning",
            stringsAsFactors = FALSE
        ))
    }

    issues <- list()
    local_vars <- names(data)

    # Check 1: Required variables missing
    req_vars <- domain_spec %>%
        filter(Core == "Req") %>%
        pull(Variable)
    missing_req <- setdiff(req_vars, local_vars)

    if (length(missing_req) > 0) {
        issues[[length(issues) + 1]] <- data.frame(
            Dataset = ds_name,
            Variable = missing_req,
            Issue = "Required variable missing",
            Severity = "Error",
            stringsAsFactors = FALSE
        )
    }

    # Check 2: Variable metadata (Type)
    # Iterate over variables present in both
    common_vars <- intersect(local_vars, domain_spec$Variable)

    for (var in common_vars) {
        std_type <- domain_spec %>%
            filter(Variable == var) %>%
            pull(Type)
        # std_type is usually "Char" or "Num"

        local_col <- data[[var]]
        local_type <- if (is.numeric(local_col)) "Num" else "Char"

        if (!is.na(std_type) && std_type != local_type) {
            issues[[length(issues) + 1]] <- data.frame(
                Dataset = ds_name,
                Variable = var,
                Issue = paste("Type mismatch. Expected:", std_type, "Found:", local_type),
                Severity = "Error",
                stringsAsFactors = FALSE
            )
        }
    }

    # Check 3: Unexpected variables (Optional, maybe just a note)
    extra_vars <- setdiff(local_vars, domain_spec$Variable)
    if (length(extra_vars) > 0) {
        issues[[length(issues) + 1]] <- data.frame(
            Dataset = ds_name,
            Variable = extra_vars,
            Issue = "Variable not in standard",
            Severity = "Info",
            stringsAsFactors = FALSE
        )
    }

    if (length(issues) > 0) {
        return(do.call(rbind, issues))
    } else {
        return(NULL)
    }
}

#' Run Validation
run_cdisc_validation <- function() {
    log_section("VALIDATING AGAINST CDISC STANDARDS")

    # Load SDTM Standard
    # Check locally cached file first
    spec <- load_standard(CDISC_SDTM_VERSION)

    if (is.null(spec)) {
        stop("Cannot proceed without cached standards. Please run '04_Fetch_CDISC_Standards.R' first.")
    }

    # List all SAS datasets
    files <- list.files(
        path = c(CDB_LIB_PATH, "d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas/cdb_lib", "d:/Siriyak IMP Data/Desktop/DQCC_Study/CDB/sas"), # Search paths
        pattern = "\\.sas7bdat$",
        full.names = TRUE,
        recursive = FALSE
    )

    log_message(paste("Found", length(files), "datasets to validate"))

    all_issues <- list()

    for (file in files) {
        ds_name <- tools::file_path_sans_ext(basename(file))
        ds_name_upper <- toupper(ds_name)

        log_message(paste("Validating:", ds_name))

        tryCatch(
            {
                data <- read_sas(file)
                names(data) <- toupper(names(data)) # Normalize to upper case for comparison

                # Use upper case domain name for lookup if needed
                # But standard might have specific casing? usually domains are uppercase e.g. AE

                issues <- validate_dataset(data, ds_name_upper, spec)

                if (!is.null(issues)) {
                    all_issues[[ds_name]] <- issues
                }
            },
            error = function(e) {
                log_message(paste("Error reading/validating", ds_name, ":", e$message), level = "ERROR")
            }
        )
    }

    # Combine and Export Report
    if (length(all_issues) > 0) {
        final_report <- do.call(rbind, all_issues)

        output_file <- get_output_path(paste0("cdisc_validation_report_", get_date_string(), ".xlsx"))
        write.xlsx(final_report, output_file)

        log_message(paste("Validation report generated:", output_file))
        return(output_file)
    } else {
        log_message("No validation issues found!")
        return(NULL)
    }
}

# Run if called directly
if (sys.nframe() == 0) {
    run_cdisc_validation()
}

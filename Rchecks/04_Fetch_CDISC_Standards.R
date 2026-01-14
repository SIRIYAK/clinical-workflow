# =============================================================================
# Fetch CDISC Standards from CDISC Library API
# Author: Siriyak
# Description: Connects to CDISC Library API to download and cache
#              official SDTM/ADaM specifications.
# =============================================================================

source("config.R")
source("utils.R")

# Check for required packages
required_packages <- c("httr2", "jsonlite", "openxlsx", "dplyr")
for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        stop(paste("Package", pkg, "is required for this script. Please install it."))
    }
}

library(httr2)
library(jsonlite)
library(openxlsx)
library(dplyr)

#' Get CDISC API Key
#' @return API Key string
get_cdisc_api_key <- function() {
    key <- CDISC_API_KEY
    if (key == "" || is.null(key)) {
        # Check if running interactively to prompt user
        if (interactive()) {
            key <- readline(prompt = "Enter your CDISC Library API Key: ")
            if (key == "") {
                stop("API Key is required to proceed.")
            }
        } else {
            stop("CDISC_API_KEY environment variable is not set.")
        }
    }
    return(key)
}

#' Fetch Specific Standard Version details
#' @param standard_type "sdtmig" or "adamig"
#' @param version Version string (e.g. "3-2")
#' @return Data frame of standard details
fetch_standard_details <- function(standard_type = "sdtmig", version = "3-2") {
    # Construct endpoint URL
    # Example: /sdtmig/3-2/classes
    # The structure of API requests may vary, often we want the full model or dataset definitions
    # For SDTMIG, typically we want the Domains and Variables.

    # We will fetch the 'datasets' (Domains) and their variables.

    api_key <- get_cdisc_api_key()
    base_url <- CDISC_API_BASE_URL

    # Endpoint for datasets (domains)
    req_url <- paste(base_url, standard_type, version, "datasets", sep = "/")

    log_message(paste("Fetching standard from:", req_url))

    tryCatch(
        {
            req <- request(req_url) %>%
                req_headers("api-key" = api_key) %>%
                req_headers("Accept" = "application/json")

            resp <- req_perform(req)

            if (resp_status(resp) != 200) {
                stop(paste("API Request failed with status:", resp_status(resp)))
            }

            content <- resp_body_json(resp)
            domains <- content$datasets

            log_message(paste("Found", length(domains), "domains in standard"))

            all_variables <- list()

            # Iterate through domains to get variables
            # This might be slow if there are many domains, consider a batch approach if API supports it
            # Or check if there is a 'variables' global endpoint

            for (domain in domains) {
                ds_name <- domain$name
                ds_label <- domain$label
                # Link to variables usually provided or constructed
                # /sdtmig/3-2/datasets/{domain}/variables
                req_var_url <- paste(base_url, standard_type, version, "datasets", ds_name, "variables", sep = "/")

                # Add a small delay to avoid rate limiting if necessary
                Sys.sleep(0.1)

                var_req <- request(req_var_url) %>%
                    req_headers("api-key" = api_key) %>%
                    req_headers("Accept" = "application/json")

                var_resp <- req_perform(var_req)

                if (resp_status(var_resp) == 200) {
                    var_content <- resp_body_json(var_resp)
                    vars <- var_content$variables

                    # Convert to data frame
                    if (length(vars) > 0) {
                        # Extract fields
                        var_df <- do.call(rbind, lapply(vars, function(x) {
                            data.frame(
                                Domain = ds_name,
                                DomainLabel = ds_label,
                                Variable = x$name,
                                Label = x$label,
                                Type = ifelse(is.null(x$type), NA, x$type), # e.g. Char, Num
                                Core = ifelse(is.null(x$core), NA, x$core), # Req, Exp, Perm
                                Role = ifelse(is.null(x$role), NA, x$role),
                                stringsAsFactors = FALSE
                            )
                        }))
                        all_variables[[ds_name]] <- var_df
                    }
                }
            }

            # Combine all
            full_spec <- do.call(rbind, all_variables)
            return(full_spec)
        },
        error = function(e) {
            log_message(paste("Error fetching standard:", e$message), level = "ERROR")
            return(NULL)
        }
    )
}

#' Save Standard to Cache
#' @param spec Data frame of the spec
#' @param filename Filename to save as
save_cached_spec <- function(spec, filename) {
    if (is.null(spec)) {
        return(FALSE)
    }

    path <- file.path(CDISC_CACHE_DIR, filename)
    saveRDS(spec, file = path)
    log_message(paste("Cached standard saved to:", path))

    # Also save as Excel for user viewing
    excel_path <- sub(".rds$", ".xlsx", path)
    write.xlsx(spec, excel_path)
    log_message(paste("Excel copy saved to:", excel_path))

    return(TRUE)
}

# MAIN EXECUTION ----------------------------------------------------------

run_fetch_standards <- function() {
    log_section("FETCHING CDISC STANDARDS")

    # Using config versions
    # We parse the version string from 'sdtmig-3-2' to API format if needed
    # The config already matches the API path format (mostly)

    # Fetch SDTM
    version_parts <- strsplit(CDISC_SDTM_VERSION, "-")[[1]]
    # Typically API expects /sdtmig/3-2
    # Our config is sdtmig-3-2. Let's split it.
    std_type <- version_parts[1] # sdtmig
    std_ver <- paste(version_parts[2:length(version_parts)], collapse = "-") # 3-2

    log_message(paste("Attempting to fetch", std_type, "version", std_ver))

    spec <- fetch_standard_details(std_type, std_ver)

    if (!is.null(spec)) {
        save_cached_spec(spec, paste0(CDISC_SDTM_VERSION, ".rds"))
    } else {
        log_message("Failed to fetch SDTM standard.", level = "ERROR")
    }
}

# Run if called directly
if (sys.nframe() == 0) {
    run_fetch_standards()
}

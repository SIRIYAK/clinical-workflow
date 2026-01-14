# C_W.R
# Prepares CDB datasets by loading them and creating local copies with cdb_ prefix
# Original: C_W.txt (SAS)

library(haven)
library(dplyr)
library(stringr)

# Load configuration
config_path <- "../Rchecks/config.R"
if (file.exists(config_path)) {
    source(config_path)
} else {
    warning("config.R not found at ../Rchecks/config.R")
}

# The SAS script creates "cdb_" prefixed datasets in the WORK library.
# In R, we will load them into the global environment or a list.

# Define input path (from config or hardcoded fallback)
cdb_path <- if (exists("CDB_LIB_PATH")) CDB_LIB_PATH else "/lillyce/prd/ly3009104/i4v_mc_jahu/misc20/data/raw/shared/uat2/veeva"

if (dir.exists(cdb_path)) {
    files <- list.files(path = cdb_path, pattern = "\\.sas7bdat$", full.names = TRUE, ignore.case = TRUE)

    if (length(files) == 0) {
        message("No .sas7bdat files found in ", cdb_path)
    }

    for (f in files) {
        # Get base name without extension
        base_name <- tools::file_path_sans_ext(basename(f))

        # Create new name with prefix
        new_name <- paste0("cdb_", base_name)

        # Read file
        tryCatch(
            {
                ds <- read_sas(f)

                # Clean names (SAS clean_names equivalent in janitor or simple tolower)
                # The SAS script didn't explicitly clean names in the macro but often good practice.

                # Assign to global environment
                assign(new_name, ds, envir = .GlobalEnv)
                message(paste("Created dataset:", new_name))
            },
            error = function(e) {
                warning(paste("Failed to read", f, ":", e$message))
            }
        )
    }
} else {
    warning(paste("Directory does not exist:", cdb_path))
}

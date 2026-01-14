# =============================================================================
# Comparison Tool Functions (Extracted from eCompare Shiny Tool)
# Author: Siriyak (Extracted from d.txt by Jasmine Khurana)
# Date: 2026-01-14
# Description: Reusable dataset comparison functions for data validation
# =============================================================================

# Required Libraries ------------------------------------------------------
suppressPackageStartupMessages({
    library(dplyr)
    library(stringr)
    library(janitor)
})

# Main Comparison Function ------------------------------------------------

#' Compare two datasets and identify differences
#' @param old Old/reference dataset
#' @param new New dataset
#' @param ideal Optional vector of primary key columns
#' @return Data frame with comparison results
differing <- function(old, new, ideal = NULL) {
    x <- data.frame()
    y <- data.frame()
    common <- data.frame()

    # Check for column consistency and missing columns
    missing_test1 <- names(new)[!names(new) %in% names(old)] # New column in new

    if (!is.na(missing_test1[1])) {
        old[, missing_test1] <- "-" # Column not in old
    }

    missing_test2 <- names(old)[!names(old) %in% names(new)] # Old column removed

    if (!is.na(missing_test2[1])) {
        new[, missing_test2] <- "-" # Column not in new
    }

    # Replace NA with <empty> text
    old <- mutate_all(old, ~ replace(., is.na(.), "<empty>"))
    new <- mutate_all(new, ~ replace(., is.na(.), "<empty>"))

    # Find rows in old that do not have match in new (Removed)
    x <- anti_join(old, new, by = ideal)
    if (nrow(x) != 0) {
        x$daff <- "Removed"
    }

    # Find rows in new that do not have match in old (New)
    y <- anti_join(new, old, by = ideal)
    if (nrow(y) != 0) {
        y$daff <- "New"
    }

    # Find common rows and check for modifications
    old$cats <- do.call(paste0, old[, 1:ncol(old)])
    new$cats <- do.call(paste0, new[, 1:ncol(new)])

    p <- inner_join(new, old, by = ideal)

    if (nrow(p) != 0 && !is.null(ideal)) {
        # Store column names of x and y
        m <- old %>%
            select(sort(names(.))) %>%
            select(-all_of(ideal)) %>%
            colnames() %>%
            paste0(".x")

        n <- new %>%
            select(sort(names(.))) %>%
            select(-all_of(ideal)) %>%
            colnames() %>%
            paste0(".y")

        # Check whether x and y are similar
        ev <- p[as.character(m[1:length(m)])] == p[as.character(n[1:length(n)])]

        # Evaluate extent of similarity
        eval <- apply(ev, 1, sum, na.rm = TRUE)
        stat <- as.matrix(round((eval + length(ideal)) / (ncol(ev) + length(ideal)), 1))

        colnames(ev) <- gsub(".x", "", colnames(ev))
        p <- cbind(p, ev, stat)
        p <- p %>% arrange(desc(stat))

        # Only the highest stat score picked up
        infor <- do.call(rbind, lapply(split(p, p$cats.x), head, 1))
        rownames(infor) <- NULL

        infor$daff <- "New" # By default everything as New
        infor$modified_info <- "NA" # Store which column is modified

        for (i in 1:nrow(infor)) {
            if (as.numeric(as.character(infor[i, ]$stat)) == 1) {
                infor[i, ]$daff <- "No Change"
            }
            if (as.numeric(as.character(infor[i, ]$stat)) > 0.5 &&
                as.numeric(as.character(infor[i, ]$stat)) < 1) {
                infor[i, ]$daff <- "Modified"
                hop <- infor %>% select(-"cats.x", -"cats.y")
                # Store which columns got modified
                infor[i, ]$modified_info <- str_c(
                    colnames(hop)[which(hop[i, ] == FALSE)],
                    collapse = "*"
                )
            }
        }

        common <- infor %>%
            select(
                all_of(ideal), str_subset(colnames(infor), pattern = ".x$"),
                daff, modified_info, -"cats.x"
            )

        colnames(common) <- gsub(".x", "", colnames(common))
    }

    if (nrow(p) != 0 && is.null(ideal)) {
        common <- p
        common$daff <- "No Change"
        common$modified_info <- NULL
        common$cats <- NULL
    }

    # Combine all results
    ans <- bind_rows(x, y, common) %>%
        rename(Compare_status = daff) %>%
        select(Compare_status, everything())

    # Add column status indicators
    if (!is.na(missing_test1[1]) || !is.na(missing_test2[1])) {
        ans_len <- ncol(ans)
        empty <- vector(mode = "character", length = ans_len)

        t1 <- which(names(ans) %in% missing_test1)
        if (length(t1) != 0) {
            empty[t1] <- "**NEW_COLUMN**"
        }

        t2 <- which(names(ans) %in% missing_test2)
        if (length(t2) != 0) {
            empty[t2] <- "**REMOVED_COLUMN**"
        }

        names(empty) <- names(ans)
        f <- bind_rows(empty, ans)
        row.names(f)[1] <- "Column_Status"
        return(f)
    } else {
        return(ans)
    }
}

# Wrapper Functions for Common Use Cases ---------------------------------

#' Compare two datasets with automatic cleaning
#' @param old_path Path to old dataset (SAS or Excel)
#' @param new_path Path to new dataset (SAS or Excel)
#' @param key_vars Optional vector of key variables
#' @param select_vars Optional vector of variables to compare
#' @return Comparison results
compare_datasets <- function(old_path, new_path, key_vars = NULL, select_vars = NULL) {
    # Read datasets based on file type
    if (grepl("\\.sas7bdat$", old_path, ignore.case = TRUE)) {
        old_data <- haven::read_sas(old_path)
    } else if (grepl("\\.xlsx?$", old_path, ignore.case = TRUE)) {
        old_data <- readxl::read_excel(old_path)
    } else {
        stop("Unsupported file format for old dataset")
    }

    if (grepl("\\.sas7bdat$", new_path, ignore.case = TRUE)) {
        new_data <- haven::read_sas(new_path)
    } else if (grepl("\\.xlsx?$", new_path, ignore.case = TRUE)) {
        new_data <- readxl::read_excel(new_path)
    } else {
        stop("Unsupported file format for new dataset")
    }

    # Clean column names
    old_data <- janitor::clean_names(old_data)
    new_data <- janitor::clean_names(new_data)

    # Select specific columns if requested
    if (!is.null(select_vars)) {
        old_data <- old_data[, select_vars, drop = FALSE] %>% mutate_all(as.character)
        new_data <- new_data[, select_vars, drop = FALSE] %>% mutate_all(as.character)
    } else {
        old_data <- old_data %>% mutate_all(as.character)
        new_data <- new_data %>% mutate_all(as.character)
    }

    # Run comparison
    result <- differing(old_data, new_data, key_vars)

    return(result)
}

#' Export comparison results to Excel with formatting
#' @param comparison_result Result from differing() function
#' @param output_path Path for output Excel file
#' @return Invisible TRUE on success
export_comparison <- function(comparison_result, output_path) {
    wb <- openxlsx::createWorkbook()
    openxlsx::addWorksheet(wb, "output")

    # Define styles
    negStyle <- openxlsx::createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE") # Red
    neutStyle <- openxlsx::createStyle(fontColour = "#FFFFFF", bgFill = "#4F81BD") # Blue
    topsStyle <- openxlsx::createStyle(fontColour = "#FFFFFF", bgFill = "#1A33CC") # Dark blue
    yosStyle <- openxlsx::createStyle(fontColour = "#006100", bgFill = "yellow") # Yellow

    # Write data
    openxlsx::writeData(wb, "output", comparison_result)

    lens <- nrow(comparison_result) + 1
    cons <- ncol(comparison_result)

    # Apply conditional formatting
    openxlsx::conditionalFormatting(wb, "output",
        cols = 1, rows = 1:lens,
        type = "contains", rule = "Removed", style = negStyle
    )
    openxlsx::conditionalFormatting(wb, "output",
        cols = 1, rows = 1:lens,
        type = "contains", rule = "Modified", style = topsStyle
    )
    openxlsx::conditionalFormatting(wb, "output",
        cols = 1, rows = 1:lens,
        type = "contains", rule = "No Change", style = neutStyle
    )
    openxlsx::conditionalFormatting(wb, "output",
        cols = 1, rows = 1:lens,
        type = "contains", rule = "New", style = yosStyle
    )

    # Column status formatting
    openxlsx::conditionalFormatting(wb, "output",
        cols = 1:cons, rows = 1:2,
        type = "contains", rule = "**NEW_COLUMN**", style = yosStyle
    )
    openxlsx::conditionalFormatting(wb, "output",
        cols = 1:cons, rows = 1:2,
        type = "contains", rule = "**REMOVED_COLUMN**", style = negStyle
    )

    # Save workbook
    openxlsx::saveWorkbook(wb, output_path, overwrite = TRUE)

    message(paste("Comparison exported to:", output_path))

    return(invisible(TRUE))
}

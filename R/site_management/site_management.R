# ==============================================================================
# Site Management Utilities
# Script: site_management.R
# Purpose: Manage study sites, generate site numbers, and maintain site registry
# ==============================================================================

source("R/setup/00_install_packages.R")

library(dplyr)
library(glue)

cat("\n========================================\n")
cat("Site Management Utilities\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Initialize Site Registry
# ==============================================================================

initialize_site_registry <- function() {
  
  site_registry <- tibble(
    Site_Number = character(),
    Site_Name = character(),
    Site_Country = character(),
    Site_Region = character(),
    Principal_Investigator = character(),
    PI_Email = character(),
    PI_Phone = character(),
    Site_Address = character(),
    Site_City = character(),
    Site_State = character(),
    Site_Postal_Code = character(),
    IRB_Name = character(),
    IRB_Approval_Date = as.Date(character()),
    Site_Activation_Date = as.Date(character()),
    Site_Status = character(),  # Active, Inactive, Closed
    Target_Enrollment = integer(),
    Actual_Enrollment = integer(),
    Comments = character()
  )
  
  dir.create("docs", showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(site_registry, "docs/Site_Registry.xlsx")
  
  cat("✓ Site registry initialized: docs/Site_Registry.xlsx\n\n")
  
  return(site_registry)
}

# ==============================================================================
# 2. Generate Site Number
# ==============================================================================

generate_site_number <- function(country_code = "US", sequential_number = 1, 
                                format = "CCC-NNN") {
  
  # Format options:
  # "CCC-NNN" = Country code (3 chars) - Sequential number (3 digits)
  # "CCNNN" = Country code + Sequential number (no separator)
  # "NNN" = Sequential number only
  # "RRRNNN" = Region (3 chars) + Sequential number
  
  site_number <- switch(format,
    "CCC-NNN" = glue("{toupper(country_code)}-{sprintf('%03d', sequential_number)}"),
    "CCNNN" = glue("{toupper(country_code)}{sprintf('%03d', sequential_number)}"),
    "NNN" = sprintf("%03d", sequential_number),
    "RRRNNN" = glue("{toupper(country_code)}{sprintf('%03d', sequential_number)}"),
    glue("{sprintf('%03d', sequential_number)}")  # Default
  )
  
  return(as.character(site_number))
}

# ==============================================================================
# 3. Add Site to Registry
# ==============================================================================

add_site <- function(site_name, country, principal_investigator,
                    region = "", pi_email = "", pi_phone = "",
                    site_address = "", city = "", state = "", postal_code = "",
                    irb_name = "", irb_approval_date = NA,
                    activation_date = Sys.Date(),
                    target_enrollment = 0,
                    format = "CCC-NNN") {
  
  registry_file <- "docs/Site_Registry.xlsx"
  
  # Load existing registry
  if (file.exists(registry_file)) {
    site_registry <- readxl::read_excel(registry_file)
    
    # Get next sequential number for this country
    country_sites <- site_registry %>% 
      filter(Site_Country == country)
    
    if (nrow(country_sites) > 0) {
      # Extract sequential numbers and get max
      existing_numbers <- as.numeric(gsub(".*-(\\d+)$", "\\1", country_sites$Site_Number))
      next_number <- max(existing_numbers, na.rm = TRUE) + 1
    } else {
      next_number <- 1
    }
  } else {
    site_registry <- initialize_site_registry()
    next_number <- 1
  }
  
  # Generate site number
  site_number <- generate_site_number(country, next_number, format)
  
  # Create new site entry
  new_site <- tibble(
    Site_Number = site_number,
    Site_Name = site_name,
    Site_Country = country,
    Site_Region = region,
    Principal_Investigator = principal_investigator,
    PI_Email = pi_email,
    PI_Phone = pi_phone,
    Site_Address = site_address,
    Site_City = city,
    Site_State = state,
    Site_Postal_Code = postal_code,
    IRB_Name = irb_name,
    IRB_Approval_Date = as.Date(irb_approval_date),
    Site_Activation_Date = as.Date(activation_date),
    Site_Status = "Active",
    Target_Enrollment = as.integer(target_enrollment),
    Actual_Enrollment = 0L,
    Comments = ""
  )
  
  # Add to registry
  updated_registry <- bind_rows(site_registry, new_site)
  
  # Save
  writexl::write_xlsx(updated_registry, registry_file)
  
  cat("✓ Site added to registry\n")
  cat(glue("  Site Number: {site_number}\n"))
  cat(glue("  Site Name: {site_name}\n"))
  cat(glue("  Country: {country}\n"))
  cat(glue("  PI: {principal_investigator}\n\n"))
  
  return(new_site)
}

# ==============================================================================
# 4. Update Site Status
# ==============================================================================

update_site_status <- function(site_number, status, comments = "") {
  
  registry_file <- "docs/Site_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Site registry not found. Run initialize_site_registry() first.\n\n")
    return(NULL)
  }
  
  site_registry <- readxl::read_excel(registry_file)
  
  # Update status
  site_registry <- site_registry %>%
    mutate(
      Site_Status = if_else(Site_Number == site_number, status, Site_Status),
      Comments = if_else(Site_Number == site_number & comments != "", 
                        paste(Comments, comments, sep = "; "), 
                        Comments)
    )
  
  writexl::write_xlsx(site_registry, registry_file)
  
  cat(glue("✓ Site {site_number} status updated to: {status}\n\n"))
  
  return(site_registry)
}

# ==============================================================================
# 5. Update Site Enrollment
# ==============================================================================

update_site_enrollment <- function(site_number, actual_enrollment) {
  
  registry_file <- "docs/Site_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Site registry not found.\n\n")
    return(NULL)
  }
  
  site_registry <- readxl::read_excel(registry_file)
  
  # Update enrollment
  site_registry <- site_registry %>%
    mutate(
      Actual_Enrollment = if_else(Site_Number == site_number, 
                                  as.integer(actual_enrollment), 
                                  as.integer(Actual_Enrollment))
    )
  
  writexl::write_xlsx(site_registry, registry_file)
  
  cat(glue("✓ Site {site_number} enrollment updated to: {actual_enrollment}\n\n"))
  
  return(site_registry)
}

# ==============================================================================
# 6. View Site Registry
# ==============================================================================

view_site_registry <- function(status = NULL, country = NULL) {
  
  registry_file <- "docs/Site_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Site registry not found.\n\n")
    return(NULL)
  }
  
  site_registry <- readxl::read_excel(registry_file)
  
  # Filter by status
  if (!is.null(status)) {
    site_registry <- site_registry %>% filter(Site_Status == status)
  }
  
  # Filter by country
  if (!is.null(country)) {
    site_registry <- site_registry %>% filter(Site_Country == country)
  }
  
  cat("\n========================================\n")
  cat("Site Registry\n")
  cat("========================================\n\n")
  
  if (nrow(site_registry) == 0) {
    cat("No sites found.\n\n")
    return(NULL)
  }
  
  print(site_registry %>% 
    select(Site_Number, Site_Name, Site_Country, Principal_Investigator, 
           Site_Status, Target_Enrollment, Actual_Enrollment))
  
  cat("\n")
  cat(glue("Total Sites: {nrow(site_registry)}\n"))
  cat(glue("Active Sites: {sum(site_registry$Site_Status == 'Active', na.rm = TRUE)}\n"))
  cat(glue("Total Enrollment: {sum(site_registry$Actual_Enrollment, na.rm = TRUE)}\n\n"))
  
  return(site_registry)
}

# ==============================================================================
# 7. Generate Site Summary Report
# ==============================================================================

generate_site_summary_report <- function() {
  
  registry_file <- "docs/Site_Registry.xlsx"
  
  if (!file.exists(registry_file)) {
    cat("❌ Site registry not found.\n\n")
    return(NULL)
  }
  
  site_registry <- readxl::read_excel(registry_file)
  
  # Summary by country
  country_summary <- site_registry %>%
    group_by(Site_Country) %>%
    summarise(
      N_Sites = n(),
      Active_Sites = sum(Site_Status == "Active", na.rm = TRUE),
      Target_Enrollment = sum(Target_Enrollment, na.rm = TRUE),
      Actual_Enrollment = sum(Actual_Enrollment, na.rm = TRUE),
      Enrollment_Rate = round(Actual_Enrollment / Target_Enrollment * 100, 1),
      .groups = "drop"
    )
  
  # Summary by status
  status_summary <- site_registry %>%
    count(Site_Status, name = "N_Sites")
  
  # Overall summary
  overall_summary <- tibble(
    Metric = c(
      "Total Sites",
      "Active Sites",
      "Inactive Sites",
      "Closed Sites",
      "Total Target Enrollment",
      "Total Actual Enrollment",
      "Overall Enrollment Rate (%)"
    ),
    Value = c(
      nrow(site_registry),
      sum(site_registry$Site_Status == "Active", na.rm = TRUE),
      sum(site_registry$Site_Status == "Inactive", na.rm = TRUE),
      sum(site_registry$Site_Status == "Closed", na.rm = TRUE),
      sum(site_registry$Target_Enrollment, na.rm = TRUE),
      sum(site_registry$Actual_Enrollment, na.rm = TRUE),
      round(sum(site_registry$Actual_Enrollment, na.rm = TRUE) / 
            sum(site_registry$Target_Enrollment, na.rm = TRUE) * 100, 1)
    )
  )
  
  # Save report
  report_list <- list(
    Overall_Summary = overall_summary,
    Country_Summary = country_summary,
    Status_Summary = status_summary,
    Site_Details = site_registry
  )
  
  writexl::write_xlsx(report_list, "outputs/Site_Summary_Report.xlsx")
  
  cat("✓ Site summary report generated: outputs/Site_Summary_Report.xlsx\n\n")
  
  cat("Overall Summary:\n")
  print(overall_summary)
  cat("\n")
  
  cat("Country Summary:\n")
  print(country_summary)
  cat("\n")
  
  return(report_list)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Site Management Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Initialize registry:\n")
cat("initialize_site_registry()\n\n")

cat("# Add site:\n")
cat('add_site(\n')
cat('  site_name = "Memorial Hospital",\n')
cat('  country = "USA",\n')
cat('  principal_investigator = "Dr. John Smith",\n')
cat('  city = "New York",\n')
cat('  target_enrollment = 30\n')
cat(')\n\n')

cat("# View registry:\n")
cat("view_site_registry()\n\n")

cat("# Update enrollment:\n")
cat('update_site_enrollment("USA-001", 15)\n\n')

cat("# Generate report:\n")
cat("generate_site_summary_report()\n\n")

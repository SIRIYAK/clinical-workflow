# ==============================================================================
# Planned Unblinding Procedures
# Script: planned_unblinding.R
# Purpose: Handle interim and final analysis unblinding
# ==============================================================================

source("R/blinding/blinding_utilities.R")

cat("\n========================================\n")
cat("Planned Unblinding Procedures\n")
cat("========================================\n\n")

# ==============================================================================
# Interim Analysis Unblinding
# ==============================================================================

interim_analysis_unblinding <- function(analysis_number, data_cutoff_date, 
                                       unblinded_statistician = "") {
  
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          INTERIM ANALYSIS UNBLINDING                           ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat(glue("Analysis Number: {analysis_number}\n"))
  cat(glue("Data Cutoff Date: {data_cutoff_date}\n"))
  cat(glue("Unblinding Date: {Sys.Date()}\n"))
  cat(glue("Unblinded Statistician: {unblinded_statistician}\n\n"))
  
  # Log the event
  log_entry <- log_blinding_event(
    event_type = "Planned Unblinding - Interim Analysis",
    subject_id = "All subjects",
    requested_by = "Data Monitoring Committee",
    reason = glue("Interim Analysis #{analysis_number}"),
    approved_by = "Study Sponsor",
    treatment_revealed = "Full unblinding for DMC only",
    documentation = glue("DMC Report #{analysis_number}"),
    comments = glue("Unblinded statistician: {unblinded_statistician}; Study team remains blinded")
  )
  
  cat("✓ Interim analysis unblinding logged\n\n")
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║                    RESPONSIBILITIES                            ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("UNBLINDED STATISTICIAN:\n")
  cat("  ✓ Prepare unblinded DMC report\n")
  cat("  ✓ Maintain strict confidentiality\n")
  cat("  ✓ NO communication with blinded study team\n")
  cat("  ✓ Store unblinded files in secure location\n")
  cat("  ✓ Use separate computer/workspace if possible\n\n")
  
  cat("BLINDED STUDY TEAM:\n")
  cat("  ✓ Remain blinded to treatment assignments\n")
  cat("  ✓ Continue study operations as planned\n")
  cat("  ✓ Do NOT access unblinded files\n")
  cat("  ✓ Do NOT discuss results with unblinded statistician\n\n")
  
  cat("DMC:\n")
  cat("  ✓ Review unblinded data\n")
  cat("  ✓ Assess safety and efficacy\n")
  cat("  ✓ Make recommendation (continue/stop/modify)\n")
  cat("  ✓ Maintain confidentiality\n\n")
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║                    NEXT STEPS                                  ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("1. ☐ Create unblinded dataset for DMC\n")
  cat("2. ☐ Generate unblinded DMC report\n")
  cat("3. ☐ Conduct DMC meeting\n")
  cat("4. ☐ Document DMC recommendations\n")
  cat("5. ☐ Implement DMC recommendations (if any)\n")
  cat("6. ☐ Continue study with blinding maintained\n\n")
  
  return(log_entry)
}

# ==============================================================================
# Final Analysis Unblinding
# ==============================================================================

final_analysis_unblinding <- function(database_lock_date, locked_by = "") {
  
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          FINAL ANALYSIS UNBLINDING                             ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat(glue("Database Lock Date: {database_lock_date}\n"))
  cat(glue("Locked by: {locked_by}\n"))
  cat(glue("Unblinding Date: {Sys.Date()}\n\n"))
  
  # Confirm database lock
  cat("⚠ CRITICAL: Confirm database is LOCKED before proceeding\n\n")
  
  response <- readline(prompt = "Is database locked? (yes/no): ")
  
  if (tolower(response) != "yes") {
    cat("\n❌ UNBLINDING ABORTED\n")
    cat("   Database must be locked before unblinding\n\n")
    return(NULL)
  }
  
  # Log the event
  log_entry <- log_blinding_event(
    event_type = "Planned Unblinding - Final Analysis",
    subject_id = "All subjects",
    requested_by = "Study Sponsor",
    reason = "Final analysis after database lock",
    approved_by = "Study Sponsor",
    treatment_revealed = "Full unblinding to all parties",
    documentation = "Final Statistical Report",
    comments = glue("Database locked on {database_lock_date} by {locked_by}")
  )
  
  cat("\n✓ Final analysis unblinding logged\n\n")
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║                    UNMASKING TREATMENTS                        ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("Treatment assignments will be unmasked:\n\n")
  
  cat("  Treatment 1 → [ENTER ACTUAL TREATMENT NAME]\n")
  cat("  Treatment 2 → [ENTER ACTUAL TREATMENT NAME]\n")
  cat("  Treatment 3 → [ENTER ACTUAL TREATMENT NAME]\n\n")
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║                    NEXT STEPS                                  ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("1. ☐ Unmask treatment assignments in analysis datasets\n")
  cat("     Run: unmask_treatment_assignments(adsl)\n\n")
  
  cat("2. ☐ Generate unblinded TLF outputs\n")
  cat("     Run: source('R/tlf/generate_all_tlf.R')\n\n")
  
  cat("3. ☐ Perform final statistical analyses\n\n")
  
  cat("4. ☐ Prepare Clinical Study Report (CSR)\n")
  cat("     Run: source('R/documents/generate_csr_document.R')\n\n")
  
  cat("5. ☐ Communicate results to study team\n\n")
  
  cat("6. ☐ Prepare regulatory submission package\n")
  cat("     Run: source('R/analysis/prepare_ofs.R')\n\n")
  
  return(log_entry)
}

# ==============================================================================
# Unmask All Datasets
# ==============================================================================

unmask_all_datasets <- function() {
  
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          UNMASKING ALL DATASETS                                ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("⚠ WARNING: This will unmask treatment assignments in ALL datasets\n\n")
  
  response <- readline(prompt = "Are you sure? (yes/no): ")
  
  if (tolower(response) != "yes") {
    cat("\n❌ UNMASKING ABORTED\n\n")
    return(NULL)
  }
  
  # List of ADaM datasets to unmask
  adam_datasets <- c("adsl", "adae", "adlb", "advs", "adeg", "adcm")
  
  unmasked_count <- 0
  
  for (dataset_name in adam_datasets) {
    dataset_file <- file.path("data/adam", paste0(dataset_name, ".sas7bdat"))
    
    if (file.exists(dataset_file)) {
      cat(glue("Unmasking {toupper(dataset_name)}...\n"))
      
      # Read dataset
      data <- haven::read_sas(dataset_file)
      
      # Unmask
      data_unmasked <- unmask_treatment_assignments(data)
      
      # Save unmasked version
      haven::write_sas(data_unmasked, dataset_file)
      
      unmasked_count <- unmasked_count + 1
    }
  }
  
  cat(glue("\n✓ Unmasked {unmasked_count} datasets\n\n"))
  
  cat("NEXT: Regenerate TLF outputs with unmasked data\n")
  cat("Run: source('R/tlf/generate_all_tlf.R')\n\n")
  
  return(unmasked_count)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Planned Unblinding Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Interim Analysis:\n")
cat('interim_analysis_unblinding(\n')
cat('  analysis_number = 1,\n')
cat('  data_cutoff_date = "2024-06-30",\n')
cat('  unblinded_statistician = "Dr. Jane Doe"\n')
cat(')\n\n')

cat("# Final Analysis:\n")
cat('final_analysis_unblinding(\n')
cat('  database_lock_date = "2024-12-15",\n')
cat('  locked_by = "Data Management Team"\n')
cat(')\n\n')

cat("# Unmask All Datasets:\n")
cat('unmask_all_datasets()\n\n')

# ==============================================================================
# SDTM/ADaM/BDM Automation Framework
# Master Automation Script: run_all.R
# Purpose: Orchestrate complete SDTM/ADaM/BDM generation pipeline
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("  SDTM/ADaM/BDM Automation Framework\n")
cat("  Master Execution Script\n")
cat("================================================================================\n\n")

# ==============================================================================
# 0. Setup and Configuration
# ==============================================================================

cat("[Phase 0] Setup and Configuration\n")
cat("--------------------------------------------------------------------------------\n")

# Source setup scripts
source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

# Initialize master log
master_log <- init_log("master_run_all")

# Track execution time
start_time <- Sys.time()

# Create execution summary
execution_summary <- list()

# ==============================================================================
# 1. SDTM Domain Generation
# ==============================================================================

cat("\n[Phase 1] SDTM Domain Generation\n")
cat("================================================================================\n\n")

log_message("Starting SDTM domain generation...")

sdtm_scripts <- c(
  "R/sdtm/sdtm_dm.R",      # Demographics
  "R/sdtm/sdtm_ex.R",      # Exposure (needed for DM reference dates)
  "R/sdtm/sdtm_ds.R",      # Disposition
  "R/sdtm/sdtm_ae.R",      # Adverse Events
  "R/sdtm/sdtm_cm.R",      # Concomitant Medications
  "R/sdtm/sdtm_vs.R",      # Vital Signs
  "R/sdtm/sdtm_lb.R",      # Laboratory
  "R/sdtm/sdtm_eg.R",      # ECG
  "R/sdtm/sdtm_mh.R",      # Medical History
  "R/sdtm/sdtm_su.R"       # Substance Use
)

for (script in sdtm_scripts) {
  if (file.exists(script)) {
    script_name <- basename(script)
    cat(glue("\n  Executing: {script_name}\n"))
    cat("  ", strrep("-", 76), "\n")
    
    script_start <- Sys.time()
    
    tryCatch({
      source(script, echo = FALSE)
      script_end <- Sys.time()
      elapsed <- difftime(script_end, script_start, units = "secs")
      
      execution_summary[[script_name]] <- list(
        status = "SUCCESS",
        elapsed = round(as.numeric(elapsed), 2)
      )
      
      cat(glue("  ✓ Completed in {round(elapsed, 2)} seconds\n"))
      log_message(glue("✓ {script_name} completed successfully"))
      
    }, error = function(e) {
      script_end <- Sys.time()
      elapsed <- difftime(script_end, script_start, units = "secs")
      
      execution_summary[[script_name]] <- list(
        status = "FAILED",
        elapsed = round(as.numeric(elapsed), 2),
        error = as.character(e)
      )
      
      cat(glue("  ✗ FAILED: {e$message}\n"))
      log_message(glue("✗ {script_name} FAILED: {e$message}"), level = "ERROR")
    })
  } else {
    cat(glue("  ⚠ Script not found: {script}\n"))
    log_message(glue("WARNING: Script not found: {script}"), level = "WARN")
  }
}

# ==============================================================================
# 2. ADaM Dataset Generation
# ==============================================================================

cat("\n[Phase 2] ADaM Dataset Generation\n")
cat("================================================================================\n\n")

log_message("Starting ADaM dataset generation...")

adam_scripts <- c(
  "R/adam/adam_adsl.R",    # Subject-Level Analysis (must be first)
  "R/adam/adam_adae.R",    # Adverse Events Analysis
  "R/adam/adam_adlb.R",    # Laboratory Analysis
  "R/adam/adam_advs.R",    # Vital Signs Analysis
  "R/adam/adam_adeg.R",    # ECG Analysis
  "R/adam/adam_adcm.R"     # Concomitant Medications Analysis
)

for (script in adam_scripts) {
  if (file.exists(script)) {
    script_name <- basename(script)
    cat(glue("\n  Executing: {script_name}\n"))
    cat("  ", strrep("-", 76), "\n")
    
    script_start <- Sys.time()
    
    tryCatch({
      source(script, echo = FALSE)
      script_end <- Sys.time()
      elapsed <- difftime(script_end, script_start, units = "secs")
      
      execution_summary[[script_name]] <- list(
        status = "SUCCESS",
        elapsed = round(as.numeric(elapsed), 2)
      )
      
      cat(glue("  ✓ Completed in {round(elapsed, 2)} seconds\n"))
      log_message(glue("✓ {script_name} completed successfully"))
      
    }, error = function(e) {
      script_end <- Sys.time()
      elapsed <- difftime(script_end, script_start, units = "secs")
      
      execution_summary[[script_name]] <- list(
        status = "FAILED",
        elapsed = round(as.numeric(elapsed), 2),
        error = as.character(e)
      )
      
      cat(glue("  ✗ FAILED: {e$message}\n"))
      log_message(glue("✗ {script_name} FAILED: {e$message}"), level = "ERROR")
    })
  } else {
    cat(glue("  ⚠ Script not found: {script}\n"))
    log_message(glue("WARNING: Script not found: {script}"), level = "WARN")
  }
}

# ==============================================================================
# 3. Generate Summary Report
# ==============================================================================

cat("\n[Phase 3] Generating Summary Report\n")
cat("================================================================================\n\n")

end_time <- Sys.time()
total_elapsed <- difftime(end_time, start_time, units = "mins")

# Count successes and failures
success_count <- sum(sapply(execution_summary, function(x) x$status == "SUCCESS"))
failure_count <- sum(sapply(execution_summary, function(x) x$status == "FAILED"))

# Create summary report
cat("\n")
cat("================================================================================\n")
cat("  EXECUTION SUMMARY\n")
cat("================================================================================\n\n")
cat(glue("Start Time:      {format(start_time, '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("End Time:        {format(end_time, '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("Total Duration:  {round(total_elapsed, 2)} minutes\n\n"))
cat(glue("Scripts Executed: {length(execution_summary)}\n"))
cat(glue("  ✓ Successful:   {success_count}\n"))
cat(glue("  ✗ Failed:       {failure_count}\n\n"))

cat("Script Details:\n")
cat(strrep("-", 80), "\n")
cat(sprintf("%-30s %-12s %-12s\n", "Script", "Status", "Time (sec)"))
cat(strrep("-", 80), "\n")

for (script_name in names(execution_summary)) {
  info <- execution_summary[[script_name]]
  status_symbol <- if (info$status == "SUCCESS") "✓" else "✗"
  cat(sprintf("%-30s %-12s %-12.2f\n", 
              script_name, 
              paste(status_symbol, info$status), 
              info$elapsed))
}

cat(strrep("-", 80), "\n\n")

# List generated files
cat("Generated SDTM Datasets:\n")
cat(strrep("-", 80), "\n")
sdtm_files <- list.files(PATHS$sdtm, pattern = "\\.(sas7bdat|xpt|csv)$")
if (length(sdtm_files) > 0) {
  for (file in sdtm_files) {
    file_size <- file.size(file.path(PATHS$sdtm, file))
    cat(sprintf("  %-40s %10.2f KB\n", file, file_size / 1024))
  }
} else {
  cat("  No SDTM datasets generated\n")
}

cat("\nGenerated ADaM Datasets:\n")
cat(strrep("-", 80), "\n")
adam_files <- list.files(PATHS$adam, pattern = "\\.(sas7bdat|xpt|csv)$")
if (length(adam_files) > 0) {
  for (file in adam_files) {
    file_size <- file.size(file.path(PATHS$adam, file))
    cat(sprintf("  %-40s %10.2f KB\n", file, file_size / 1024))
  }
} else {
  cat("  No ADaM datasets generated\n")
}

cat("\nGenerated BDM Specifications:\n")
cat(strrep("-", 80), "\n")
bdm_files <- list.files(PATHS$bdm, pattern = "\\.xlsx$")
if (length(bdm_files) > 0) {
  for (file in bdm_files) {
    file_size <- file.size(file.path(PATHS$bdm, file))
    cat(sprintf("  %-40s %10.2f KB\n", file, file_size / 1024))
  }
} else {
  cat("  No BDM specifications generated\n")
}

cat("\n")
cat("================================================================================\n")

if (failure_count == 0) {
  cat("  ✓ ALL SCRIPTS EXECUTED SUCCESSFULLY!\n")
  log_message("✓ Master automation completed successfully")
} else {
  cat("  ⚠ SOME SCRIPTS FAILED - Please review logs for details\n")
  log_message("⚠ Master automation completed with errors", level = "WARN")
}

cat("================================================================================\n\n")

# Save execution summary to file
summary_file <- file.path(PATHS$reports, glue("execution_summary_{format(Sys.time(), '%Y%m%d_%H%M%S')}.txt"))
sink(summary_file)
cat("SDTM/ADaM/BDM Automation Framework - Execution Summary\n")
cat(strrep("=", 80), "\n\n")
cat(glue("Execution Date: {format(Sys.time(), '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("Total Duration: {round(total_elapsed, 2)} minutes\n\n"))
print(execution_summary)
sink()

cat(glue("Execution summary saved to: {basename(summary_file)}\n\n"))

# Close master log
close_log()

cat("✓ Master automation script completed!\n\n")

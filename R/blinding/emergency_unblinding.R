# ==============================================================================
# Emergency Unblinding Procedures
# Script: emergency_unblinding.R
# Purpose: Handle emergency unblinding requests
# ==============================================================================

source("R/blinding/blinding_utilities.R")

library(officer)

cat("\n========================================\n")
cat("Emergency Unblinding Procedures\n")
cat("========================================\n\n")

# ==============================================================================
# Emergency Unblinding Request
# ==============================================================================

emergency_unblinding <- function(subject_id, reason, requested_by, 
                                 site_number = "", approved_by = "",
                                 treatment_revealed = "") {
  
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          EMERGENCY UNBLINDING REQUEST                         ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat(glue("Subject ID: {subject_id}\n"))
  cat(glue("Site Number: {site_number}\n"))
  cat(glue("Requested by: {requested_by}\n"))
  cat(glue("Reason: {reason}\n"))
  cat(glue("Date/Time: {Sys.time()}\n\n"))
  
  # Generate emergency unblinding form
  form_file <- generate_emergency_unblinding_form(subject_id, reason, requested_by, site_number)
  
  # Log the event
  log_entry <- log_blinding_event(
    event_type = "Emergency Unblinding",
    subject_id = subject_id,
    requested_by = requested_by,
    reason = reason,
    approved_by = approved_by,
    treatment_revealed = treatment_revealed,
    documentation = glue("Emergency Unblinding Form: {basename(form_file)}"),
    comments = glue("Site: {site_number}")
  )
  
  cat("\n⚠ EMERGENCY UNBLINDING LOGGED\n")
  cat(glue("Log ID: {log_entry$Log_ID}\n\n"))
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║                    NEXT STEPS                                  ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("1. ☐ Contact Medical Monitor for approval\n")
  cat("     Name: _________________________________\n")
  cat("     Phone: _________________________________\n\n")
  
  cat("2. ☐ Contact randomization code holder\n")
  cat("     Organization: _________________________________\n")
  cat("     Contact: _________________________________\n\n")
  
  cat("3. ☐ Obtain treatment assignment\n")
  cat("     Treatment: _________________________________\n\n")
  
  cat("4. ☐ Complete emergency unblinding form\n")
  cat(glue("     File: {form_file}\n\n"))
  
  cat("5. ☐ Notify sponsor\n")
  cat("     Contact: _________________________________\n")
  cat("     Date notified: _________________________________\n\n")
  
  cat("6. ☐ Notify IRB/IEC (if required)\n")
  cat("     Date notified: _________________________________\n\n")
  
  cat("7. ☐ Update subject's source documents\n\n")
  
  cat("8. ☐ File completed form in subject's study binder\n\n")
  
  return(list(
    log_entry = log_entry,
    form_file = form_file
  ))
}

# ==============================================================================
# Generate Emergency Unblinding Form
# ==============================================================================

generate_emergency_unblinding_form <- function(subject_id, reason, requested_by, site_number) {
  
  # Create DOCX form
  doc <- read_docx()
  
  doc <- doc %>%
    body_add_par("EMERGENCY UNBLINDING FORM", style = "heading 1") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("CONFIDENTIAL", style = "heading 2") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par(glue("Study: {STUDY_CONFIG$study_id}"), style = "Normal") %>%
    body_add_par(glue("Protocol: {STUDY_CONFIG$protocol}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("SUBJECT INFORMATION", style = "heading 2") %>%
    body_add_par(glue("Subject ID: {subject_id}"), style = "Normal") %>%
    body_add_par(glue("Site Number: {site_number}"), style = "Normal") %>%
    body_add_par(glue("Date of Unblinding: {Sys.Date()}"), style = "Normal") %>%
    body_add_par(glue("Time of Unblinding: {format(Sys.time(), '%H:%M')}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("UNBLINDING REQUEST", style = "heading 2") %>%
    body_add_par(glue("Requested by: {requested_by}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Reason for Unblinding:", style = "Normal") %>%
    body_add_par("☐ Serious Adverse Event (SAE)", style = "Normal") %>%
    body_add_par("☐ Medical Emergency", style = "Normal") %>%
    body_add_par("☐ Pregnancy", style = "Normal") %>%
    body_add_par("☐ Other", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par(glue("Detailed Justification: {reason}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("APPROVALS", style = "heading 2") %>%
    body_add_par("Medical Monitor Approval:", style = "Normal") %>%
    body_add_par("Name: _________________________________", style = "Normal") %>%
    body_add_par("Signature: _________________________________", style = "Normal") %>%
    body_add_par("Date/Time: _________________________________", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Sponsor Approval (if required):", style = "Normal") %>%
    body_add_par("Name: _________________________________", style = "Normal") %>%
    body_add_par("Signature: _________________________________", style = "Normal") %>%
    body_add_par("Date/Time: _________________________________", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("TREATMENT ASSIGNMENT REVEALED", style = "heading 2") %>%
    body_add_par("Treatment Assignment: _________________________________", style = "Normal") %>%
    body_add_par("Revealed by: _________________________________", style = "Normal") %>%
    body_add_par("Method: ☐ Phone  ☐ Email  ☐ Fax  ☐ Other: _________", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("NOTIFICATIONS", style = "heading 2") %>%
    body_add_par("☐ IRB/IEC notified (Date: __________)", style = "Normal") %>%
    body_add_par("☐ Sponsor notified (Date: __________)", style = "Normal") %>%
    body_add_par("☐ Regulatory authority notified (if required) (Date: __________)", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("IMPACT ASSESSMENT", style = "heading 2") %>%
    body_add_par("☐ Subject continued in study", style = "Normal") %>%
    body_add_par("☐ Subject discontinued from study", style = "Normal") %>%
    body_add_par("☐ Subject remained blinded to treatment", style = "Normal") %>%
    body_add_par("☐ Subject was informed of treatment", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Comments: _________________________________________________________________", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("DOCUMENTATION", style = "heading 2") %>%
    body_add_par("☐ Copy of this form filed in subject's study binder", style = "Normal") %>%
    body_add_par("☐ Copy sent to sponsor", style = "Normal") %>%
    body_add_par("☐ Entry made in unblinding log", style = "Normal") %>%
    body_add_par("☐ Entry made in subject's source documents", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Completed by: _________________________________", style = "Normal") %>%
    body_add_par("Date: _________________________________", style = "Normal")
  
  # Save form
  form_file <- glue("docs/Emergency_Unblinding_Form_{subject_id}_{format(Sys.Date(), '%Y%m%d')}.docx")
  print(doc, target = form_file)
  
  cat(glue("✓ Emergency unblinding form created: {form_file}\n\n"))
  
  return(form_file)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Emergency Unblinding Functions Loaded\n\n")

cat("Example usage:\n")
cat('emergency_unblinding(\n')
cat('  subject_id = "SUBJ-0123",\n')
cat('  site_number = "001",\n')
cat('  reason = "Serious adverse event requiring knowledge of treatment",\n')
cat('  requested_by = "Dr. John Smith, Principal Investigator"\n')
cat(')\n\n')

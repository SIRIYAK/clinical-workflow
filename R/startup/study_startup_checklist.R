# ==============================================================================
# Study Startup Checklist
# Script: study_startup_checklist.R
# Purpose: Track and manage study startup activities
# ==============================================================================

source("R/setup/00_install_packages.R")

library(dplyr)
library(glue)
library(writexl)

cat("\n========================================\n")
cat("Study Startup Checklist\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Initialize Startup Checklist
# ==============================================================================

initialize_startup_checklist <- function(study_id = "STUDY-001") {
  
  startup_checklist <- tibble(
    Task_ID = sprintf("TASK-%03d", 1:30),
    Category = c(
      rep("Regulatory", 5),
      rep("Ethics", 3),
      rep("Site Activation", 7),
      rep("Training", 5),
      rep("Systems", 5),
      rep("Study Materials", 5)
    ),
    Task = c(
      # Regulatory
      "IND/CTA submission",
      "Regulatory authority approval",
      "Protocol finalization",
      "Informed consent finalization",
      "Investigator brochure finalization",
      # Ethics
      "IRB/IEC submission",
      "IRB/IEC approval",
      "Informed consent approval",
      # Site Activation
      "Site selection",
      "Confidentiality agreements",
      "Clinical trial agreements",
      "Site initiation visit scheduled",
      "Site initiation visit completed",
      "Site activation",
      "First subject screened",
      # Training
      "Protocol training materials",
      "Investigator meeting",
      "Site staff training",
      "eCRF training",
      "Safety reporting training",
      # Systems
      "eCRF build",
      "eCRF UAT",
      "eCRF go-live",
      "IWRS/IVRS setup",
      "Central lab activation",
      # Study Materials
      "Investigational product manufacturing",
      "IP labeling and packaging",
      "IP distribution to sites",
      "Study supplies distribution",
      "Source documents distribution"
    ),
    Responsible = rep("", 30),
    Target_Date = as.Date(rep(NA, 30)),
    Actual_Date = as.Date(rep(NA, 30)),
    Status = rep("Not Started", 30),
    Comments = rep("", 30)
  )
  
  dir.create("docs", showWarnings = FALSE, recursive = TRUE)
  writexl::write_xlsx(startup_checklist, glue("docs/Study_Startup_Checklist_{study_id}.xlsx"))
  
  cat(glue("✓ Study startup checklist initialized: docs/Study_Startup_Checklist_{study_id}.xlsx\n\n"))
  
  return(startup_checklist)
}

# ==============================================================================
# 2. Update Task Status
# ==============================================================================

update_task_status <- function(task_id, status, actual_date = Sys.Date(), 
                              comments = "", study_id = "STUDY-001") {
  
  checklist_file <- glue("docs/Study_Startup_Checklist_{study_id}.xlsx")
  
  if (!file.exists(checklist_file)) {
    cat("❌ Checklist not found. Run initialize_startup_checklist() first.\n\n")
    return(NULL)
  }
  
  checklist <- readxl::read_excel(checklist_file)
  
  # Update task
  checklist <- checklist %>%
    mutate(
      Status = if_else(Task_ID == task_id, status, Status),
      Actual_Date = if_else(Task_ID == task_id, as.Date(actual_date), Actual_Date),
      Comments = if_else(Task_ID == task_id & comments != "", comments, Comments)
    )
  
  writexl::write_xlsx(checklist, checklist_file)
  
  task_name <- checklist %>% filter(Task_ID == task_id) %>% pull(Task)
  cat(glue("✓ Task updated: {task_name}\n"))
  cat(glue("  Status: {status}\n\n"))
  
  return(checklist)
}

# ==============================================================================
# 3. Generate Startup Status Report
# ==============================================================================

generate_startup_status_report <- function(study_id = "STUDY-001") {
  
  checklist_file <- glue("docs/Study_Startup_Checklist_{study_id}.xlsx")
  
  if (!file.exists(checklist_file)) {
    cat("❌ Checklist not found.\n\n")
    return(NULL)
  }
  
  checklist <- readxl::read_excel(checklist_file)
  
  cat("\n========================================\n")
  cat("Study Startup Status Report\n")
  cat("========================================\n\n")
  
  # Overall summary
  overall_summary <- tibble(
    Metric = c(
      "Total Tasks",
      "Completed",
      "In Progress",
      "Not Started",
      "Delayed",
      "% Complete"
    ),
    Value = c(
      nrow(checklist),
      sum(checklist$Status == "Completed", na.rm = TRUE),
      sum(checklist$Status == "In Progress", na.rm = TRUE),
      sum(checklist$Status == "Not Started", na.rm = TRUE),
      sum(!is.na(checklist$Target_Date) & is.na(checklist$Actual_Date) & 
          checklist$Target_Date < Sys.Date(), na.rm = TRUE),
      round(sum(checklist$Status == "Completed", na.rm = TRUE) / nrow(checklist) * 100, 1)
    )
  )
  
  # By category
  category_summary <- checklist %>%
    group_by(Category) %>%
    summarise(
      Total = n(),
      Completed = sum(Status == "Completed", na.rm = TRUE),
      In_Progress = sum(Status == "In Progress", na.rm = TRUE),
      Not_Started = sum(Status == "Not Started", na.rm = TRUE),
      Pct_Complete = round(Completed / Total * 100, 1),
      .groups = "drop"
    )
  
  # Delayed tasks
  delayed_tasks <- checklist %>%
    filter(!is.na(Target_Date), is.na(Actual_Date), Target_Date < Sys.Date()) %>%
    select(Task_ID, Category, Task, Target_Date, Responsible)
  
  # Save report
  report_list <- list(
    Overall_Summary = overall_summary,
    Category_Summary = category_summary,
    Delayed_Tasks = delayed_tasks,
    Full_Checklist = checklist
  )
  
  writexl::write_xlsx(report_list, glue("outputs/Study_Startup_Status_{study_id}.xlsx"))
  
  cat("Overall Summary:\n")
  print(overall_summary)
  cat("\n")
  
  cat("Category Summary:\n")
  print(category_summary)
  cat("\n")
  
  if (nrow(delayed_tasks) > 0) {
    cat("⚠ Delayed Tasks:\n")
    print(delayed_tasks)
    cat("\n")
  }
  
  cat(glue("✓ Startup status report saved: outputs/Study_Startup_Status_{study_id}.xlsx\n\n"))
  
  return(report_list)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Study Startup Checklist Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Initialize checklist:\n")
cat('initialize_startup_checklist(study_id = "STUDY-001")\n\n')

cat("# Update task:\n")
cat('update_task_status(\n')
cat('  task_id = "TASK-001",\n')
cat('  status = "Completed",\n')
cat('  actual_date = "2024-01-15"\n')
cat(')\n\n')

cat("# Generate status report:\n")
cat('generate_startup_status_report(study_id = "STUDY-001")\n\n')

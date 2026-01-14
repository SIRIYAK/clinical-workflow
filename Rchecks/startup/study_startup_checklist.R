# =============================================================================
# Study Startup Automation Module
# Author: Siriyak
# Description: Tracks and manages study startup activities.
# =============================================================================

library(dplyr)

#' Initialize Startup Checklist
#' @param site_list Vector of site IDs
#' @return Data frame with checklist items
initialize_checklist <- function(site_list) {
    items <- c(
        "CDA Signed", "Protocol Signature", "CV Collected", "Medical License",
        "Training Log", "IRB Approval", "Contract Signed", "Site Activation"
    )

    checklist <- expand.grid(SITEID = site_list, Item = items, stringsAsFactors = FALSE)
    checklist$Status <- "Pending"
    checklist$Date_Completed <- NA

    return(checklist)
}

#' Update Checklist Item
#' @param checklist Current checklist dataframe
#' @param site_id Site ID to update
#' @param item_name checklist item name
#' @param status New status (Completed/Pending)
#' @return Updated checklist
update_checklist <- function(checklist, site_id, item_name, status = "Completed") {
    checklist %>%
        mutate(
            Status = ifelse(SITEID == site_id & Item == item_name, status, Status),
            Date_Completed = ifelse(SITEID == site_id & Item == item_name & status == "Completed",
                as.character(Sys.Date()), Date_Completed
            )
        )
}

#' Get Site Activation Readiness
#' @param checklist Current checklist
#' @return Data frame of site status
check_startup_status <- function(checklist) {
    checklist %>%
        group_by(SITEID) %>%
        summarise(
            Total_Items = n(),
            Completed_Items = sum(Status == "Completed"),
            Percent_Complete = round((Completed_Items / Total_Items) * 100, 1),
            Ready_to_Activate = (Percent_Complete == 100)
        )
}

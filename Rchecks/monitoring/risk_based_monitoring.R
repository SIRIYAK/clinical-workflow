# =============================================================================
# Risk-Based Monitoring (RBM) Module
# Author: Siriyak
# Description: Implements Key Risk Indicators (KRIs) and site risk scoring.
# =============================================================================

library(dplyr)

#' Calculate Key Risk Indicators (KRIs)
#' @param ae_data Adverse Event dataframe
#' @param dm_data Demographics dataframe (for enrolment counts)
#' @param query_data Query dataframe (optional)
#' @return Data frame with Site-level KRIs and Risk Scores
calculate_site_risk <- function(ae_data, dm_data, query_data = NULL) {
    # Site Enrollment Counts
    site_counts <- dm_data %>%
        group_by(SITEID) %>%
        summarise(Subjects = n_distinct(USUBJID), .groups = "drop")

    # KRI 1: Adverse Event Rate per Subject
    ae_rates <- ae_data %>%
        group_by(SITEID) %>%
        summarise(AE_Count = n(), .groups = "drop") %>%
        left_join(site_counts, by = "SITEID") %>%
        mutate(AE_Rate = AE_Count / Subjects)

    # KRI 2: Query Rate (if data available)
    if (!is.null(query_data)) {
        query_rates <- query_data %>%
            group_by(SITEID) %>%
            summarise(Query_Count = n(), .groups = "drop")

        risk_table <- ae_rates %>% left_join(query_rates, by = "SITEID")
    } else {
        risk_table <- ae_rates
        risk_table$Query_Count <- 0 # Default if missing
    }

    # Calculate Risk Score (Weighted Sum approach)
    # Weights: AE_Rate (High if > 5 or < 0.1), Query_Count (High if > 50)

    risk_table <- risk_table %>%
        mutate(
            AE_Risk_Score = case_when(
                AE_Rate > 10 ~ 3, # High reporting (Safety signal?)
                AE_Rate < 0.5 ~ 3, # Under-reporting (Compliance issue?)
                AE_Rate > 5 ~ 2,
                TRUE ~ 1
            ),
            Enrollment_Weight = case_when(
                Subjects > 20 ~ 2,
                TRUE ~ 1
            )
        ) %>%
        mutate(
            Total_Risk_Score = (AE_Risk_Score * 2) + Enrollment_Weight
        ) %>%
        mutate(
            Risk_Level = case_when(
                Total_Risk_Score >= 7 ~ "HIGH",
                Total_Risk_Score >= 4 ~ "MEDIUM",
                TRUE ~ "LOW"
            )
        ) %>%
        arrange(desc(Total_Risk_Score))

    return(risk_table)
}

#' Generate Monitoring Recommendations
#' @param risk_table Output from calculate_site_risk
#' @return Data frame with recommendations
generate_monitoring_actions <- function(risk_table) {
    risk_table %>%
        mutate(Recommendation = case_when(
            Risk_Level == "HIGH" ~ "Immediate On-Site Visit / Audit",
            Risk_Level == "MEDIUM" ~ "Review remotely & Schedule call",
            Risk_Level == "LOW" ~ "Routine monitoring"
        )) %>%
        select(SITEID, Risk_Level, Recommendation, everything())
}

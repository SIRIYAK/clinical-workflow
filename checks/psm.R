# psm.R
# PSM (Poisson Screening Model) - Analysis and Prediction
# Original: psm.txt (SAS)

library(dplyr)
library(stats)
library(readr)
library(lubridate)
library(haven)

# Load configuration
source("../Rchecks/config.R")
source("../Rchecks/utils.R")

# Part 1: Data Preparation ------------------------------------------------

#' Prepare data for PSM analysis
#' @param alsc_datasets List of ALSC datasets (inf_dm1001, inf_infsubject, inf_infsite, inf_ds2001)
#' @return Data frame ready for modeling (scr_v1 equivalent)
prepare_psm_data <- function(alsc_datasets) {
    # Check required datasets
    required <- c("inf_dm1001", "inf_infsubject", "inf_infsite", "inf_ds2001")
    missing_ds <- setdiff(required, names(alsc_datasets))
    if (length(missing_ds) > 0) {
        stop("Missing required datasets for PSM: ", paste(missing_ds, collapse = ", "))
    }

    dm <- alsc_datasets$inf_dm1001
    inf_sub <- alsc_datasets$inf_infsubject
    inf_site <- alsc_datasets$inf_infsite
    ds <- alsc_datasets$inf_ds2001

    # 1. Create sub table (Demographics)
    # SAS: coalesce(race_1, ...). In R, we check what columns exist.
    race_cols <- grep("race_\\d+", names(dm), value = TRUE, ignore.case = TRUE)

    sub <- dm %>%
        filter(brthyr != "") %>% # Check for NA or empty string
        mutate(
            RACE = do.call(coalesce, select(., one_of(race_cols, "race"))), # Generalized coalesce
            sex = if ("sex" %in% names(.)) sex else NA,
            ethnic = if ("ethnic" %in% names(.)) ethnic else NA,
            brthyr = if ("brthyr" %in% names(.)) brthyr else NA
        ) %>%
        distinct(subjid, subjectid, RACE, sex, ethnic, brthyr)

    # 2. Create site table
    # Join inf_subject and inf_site
    site <- inf_sub %>%
        left_join(inf_site, by = "siteid") %>%
        distinct(subjectid, country = sitecountry, site = sitemnemonic)

    # 3. Create disp table (Disposition dates)
    # SAS: DSSTDAT_I=mdy(DSSTDAT_ICMO,DSSTDAT_ICDD,DSSTDAT_ICYY);
    disp <- ds %>%
        mutate(
            # Assuming numeric month/day/year columns
            DSSTDAT_I = make_date(dsstdat_icyy, dsstdat_icmo, dsstdat_icdd)
        ) %>%
        filter(!is.na(DSSTDAT_I)) %>%
        distinct(subjid, DSSTDAT_I)

    # 4. Create sub_a
    sub_a <- site %>%
        left_join(sub, by = "subjectid") %>%
        left_join(disp, by = "subjid") %>%
        filter(!is.na(subjid))

    # 5. Logic for train/test splitting (Hardcoded dates in SAS: 31JAN2020)
    # We will keep the structure but maybe parameterize dates later.
    # For now, implementing the 'scr' table logic directly.
    # SAS joined with IRV_CUR_SITE for SITESTUDYINITIATIONDATE.
    # Missing table? Assuming available or NA.

    # Placeholder for Site Initiation Date
    # If not available, we can't calculate 'scr_days'.
    # Assuming 'inf_site' has it or similar.

    scr_data <- sub_a %>%
        group_by(site) %>%
        summarise(
            scr_total = n(),
            # Mocking days calculation if date not present
            # In real scenario, need SITESTUDYINITIATIONDATE
            scr_days = 100 # Placeholder
        )

    return(scr_data)
}

# Part 2: Modeling --------------------------------------------------------

#' Run Poisson Screening Model
#' @param scr_data Data frame with columns: site, scr_days, scr_total
#' @return List with model results
run_psm_model <- function(scr_data) {
    # Filter valid data
    model_data <- scr_data %>%
        filter(!is.na(scr_total) & !is.na(scr_days) & scr_days > 0)

    if (nrow(model_data) == 0) {
        return(NULL)
    }

    # Fits a Poisson model to estimate screening rate
    # Rate lambda = exp(alpha0) per month (30.4 days)

    model_poisson <- glm(scr_total ~ 1,
        family = poisson(link = "log"),
        offset = log(model_data$scr_days / 30.4),
        data = model_data
    )

    alpha0 <- coef(model_poisson)[1]
    psm_scr <- exp(alpha0)

    return(list(
        model = model_poisson,
        alpha0 = alpha0,
        psm_scr = psm_scr,
        aic = AIC(model_poisson)
    ))
}

# Main Execution (Commented out)
# alsc <- load_alsc_library() # Fromutils
# psm_data <- prepare_psm_data(alsc)
# results <- run_psm_model(psm_data)
# print(results)

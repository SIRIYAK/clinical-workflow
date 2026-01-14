
# 
# function that dynamically passes a dataframe alias 
# SS_LFU_01 variable BETPT and creates a new column BETPT_ based on the specified conditions:



# create_function <- function(df, var) {
#   df %>%
#     mutate(!!sym(paste0(var, "_")) := case_when(
#       !!sym(var) == 'Pre-Dose' ~ '0.0',
#       !!sym(var) == '1.0 Hour Post Dose' ~ '1.0',
#       !!sym(var) == '2.0 Hour Post Dose' ~ '2.0',
#       !!sym(var) == '4.0 Hour Post Dose' ~ '4.0',
#       !!sym(var) == '6.0 Hour Post Dose' ~ '6.0',
#       !!sym(var) == '24.0 Hour Post Dose' ~ '24.0',
#       TRUE ~ ifelse(is.numeric(!!sym(var)), !!sym(var), NA_real_)  # Return NA for non-numeric values
#     ))
# }
# 
# 
# BE_CTDNA_01<- create_function(BE_CTDNA_01, "DV_QVAL_BETPT_D")
# 
# 


create_function <- function(df, var, var2) {
  var_sym <- sym(var)
  var2_sym <- sym(paste0(var2, "_"))
  
  df %>%
    mutate(!!var2_sym := case_when(
      !!var_sym == "Pre-Dose" ~ "0.0",
      !!var_sym == "1.0 Hour Post Dose" ~ "1.0",
      !!var_sym == "2.0 Hour Post Dose" ~ "2.0",
      !!var_sym == "4.0 Hour Post Dose" ~ "4.0",
      !!var_sym == "6.0 Hour Post Dose" ~ "6.0",
      !!var_sym == "24.0 Hour Post Dose" ~ "24.0",
      TRUE ~ ifelse(is.numeric(!!var_sym), as.character(!!var_sym), NA_character_)  # Return NA for non-numeric values
    ))
}

# BE_CTDNA_01 <- create_function(BE_CTDNA_01, "DV_QVAL_BETPT_D", "DV_QVA")


# create_function <- function(df, var) {
#   df %>%
#     mutate(!!sym(paste0(var, "_")) := case_when(
#       !!sym(var) == 'Pre-Dose' ~ '0.0',
#       !!sym(var) == '1.0 Hour Post Dose' ~ '1.0',
#       !!sym(var) == '2.0 Hour Post Dose' ~ '2.0',
#       !!sym(var) == '4.0 Hour Post Dose' ~ '4.0',
#       !!sym(var) == '6.0 Hour Post Dose' ~ '6.0',
#       !!sym(var) == '24.0 Hour Post Dose' ~ '24.0',
#       TRUE ~ ifelse(is.numeric(!!sym(var)), as.character(!!sym(var)), 'NA')  # Return character 'NA' for non-numeric values
#     ))
# }
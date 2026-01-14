




date_time_split_ <- function(date_string) {
  # Split the date and time components
  date_part <- sub(" .*", "", date_string)
  time_part <- sub(".* ", "", date_string)
  
  # Return the components as a list
  return(list(date_part = date_part, time_part = time_part))
}


# Define the function to apply the transformation to the DataFrame
transform_df_ <- function(df, date_columns) {
  for (date_col in date_columns) {
    df <- df %>%
      rowwise() %>%
      mutate(
        !!paste0(date_col, "DAT") := date_time_split_(.data[[date_col]])$date_part,
        
        !!paste0(date_col, "TM") := date_time_split_(.data[[date_col]])$time_part
        
        
      ) %>%
      
      ungroup()
  }
  
  return(df)
}

# 
# # Specify the date columns to be transformed
# date_EG_GEN_01 <- c("V_EGDTC")
# 
# 
# # Apply the function to the DataFrame
# EG_UNS_01 <- transform_df_(EG_UNS_01, date_EG_GEN_01)

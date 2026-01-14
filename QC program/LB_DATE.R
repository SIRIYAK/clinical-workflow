








date_ti_sp_zero <- function(date_string_X) {
  # Split the date and time components
  date_part_X <- sub(" .*", "", date_string_X)
  time_part_X <- sub(".* ", "", date_string_X)
  
  # Extract only the "HH:MM" from the time component
  time_part_X <- format(as.POSIXct(time_part_X, format = "%H:%M:%S"), "%H:%M")
  
  # Combine the date and time components
  date_time_ <- as.POSIXct(paste(date_part_X, time_part_X),
                           format = "%Y-%m-%d %H:%M",
                           tz="")
  
  # Return the components as a list
  return(list(date_part_X = date_part_X, time_part_X = time_part_X))
}

# Define the function to apply the transformation to the DataFrame
transform_df_X <- function(df, date_col_Xumns) {
  for (date_col_X in date_col_Xumns) {
    df <- df %>%
      rowwise() %>%
      mutate(
        !!paste0(date_col_X, "DAT") := date_ti_sp_zero(.data[[date_col_X]])$date_part_X,
        
        !!paste0(date_col_X, "TM") := date_ti_sp_zero(.data[[date_col_X]])$time_part_X
        
      ) %>%
      ungroup()
  }
  
  return(df)
}





# # Specify the date columns to be transformed
# date_LB_URINUNS_01 <- c("V_LBTDTC")
# 
# # Apply the function to the DataFrame
# LB_URINUNS_01 <- transform_df_X(LB_URINUNS_01, date_LB_URINUNS_01)

# Load necessary library
# library(dplyr)
# 
# # Sample DataFrame
# df <- data.frame(
#   id = 1:3,
#   ae_start_date = c("2024-07-01T10:15:00-04:00", "2024-07-02T12:30:00-04:00", "2024-07-03T14:45:00-04:00"),
#   en_date = c("2024-07-01T11:15:00-04:00", "2024-07-02T13:30:00-04:00", "2024-07-03T15:45:00-04:00")
# )

# Define the date_time__split function
date_time__split <- function(date_string_) {
  # Extract the date and time components
  date_part_ <- sub("T.*", "", date_string_)
  time_part_ <- sub(".*T", "", date_string_)
  time_part <- sub("-.*", "", time_part_)
  
  # Combine the date and time components
  date_time_ <- as.POSIXct(paste(date_part_, time_part),
                          format = "%Y-%m-%d %H:%M",
                          tz="")
  
  strftime(date_time_) 
  # Return the components as a list
  return(list(date_part_ = date_part_, time_part = time_part, date_time_ = date_time_))
}

# Define the function to apply the transformation to the DataFrame
transform_df <- function(df, date_col_umns) {
  for (date_col_ in date_col_umns) {
    df <- df %>%
      rowwise() %>%
      mutate(
        !!paste0(date_col_, "DAT") := date_time__split(.data[[date_col_]])$date_part_,
        !!paste0("X_", date_col_, "DAT") := date_time__split(.data[[date_col_]])$date_part_,
        !!paste0(date_col_, "TM") := date_time__split(.data[[date_col_]])$time_part,
        !!paste0("X_", date_col_, "TM") := date_time__split(.data[[date_col_]])$time_part,
        !!paste0(date_col_, "DTC") := date_time__split(.data[[date_col_]])$date_time_,
        !!paste0("X_", date_col_, "DTC") := date_time__split(.data[[date_col_]])$date_time_
      ) %>%
  
      ungroup()
  }
  
  return(df)
}

# # Specify the date columns to be transformed
# date_col_umns <- c("V_AESTDTC", "V_AEENDTC")
# 
# # Apply the function to the DataFrame
# df_transformed <- transform_df(AE_SAE_01, date_col_umns)
# 
# # View the transformed DataFrame
# print(df_transformed)

# Load necessary library
# library(dplyr)
# 
# # Sample DataFrame
# df <- data.frame(
#   id = 1:3,
#   date_string = c("2024-07-01T10:15:00-04:00", "2024-07-02T12:30:00-04:00", "2024-07-03T14:45:00-04:00")
# )

# Define the date_time_split function
date_time_split <- function(date_string) {
  # Extract the date and time components
  date_part <- sub("T.*", "", date_string)
  time_part_ <- sub(".*T", "", date_string)
  time_part <- sub("-.*", "", time_part_)
  
  # Combine the date and time components
  date_time <- as.POSIXct(paste(date_part, time_part),
                          format = "%Y-%m-%d %H:%M",
                          tz="")
  
  # Return the components as a list
  return(list(date_part = date_part, time_part = time_part, date_time = date_time))
}

# Define the function to apply the transformation to the DataFrame
transform_df <- function(df) {
  df <- df %>%
    rowwise() %>%
    mutate(
      date_part = date_time_split(date_string)$date_part,
      time_part = date_time_split(date_string)$time_part,
      date_time = date_time_split(date_string)$date_time
    ) %>%
    ungroup()
  
  return(df)
}

# # Apply the function to the DataFrame
# df_transformed <- transform_df(df)
# 
# # View the transformed DataFrame
# print(df_transformed)

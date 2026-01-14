# Function to extract date and time components from a date-time string
date_time_split <- function(date_string) {
  # Extract the date and time components
  date_part <- sub("T.*", "", date_string)
  time_part <- sub(".*T", "", date_string)
  time_part <- sub("-.*", "", time_part)
  
  # Combine the date and time components
  # date_string <- paste(date_part, time_part)
  date_string <- as.POSIXct(paste(date_part, time_part),
                            format = "%Y-%m-%d %H:%M",
                            tz="")
  
  strftime(date_string) 
  # Return the result
  return(date_string)
}
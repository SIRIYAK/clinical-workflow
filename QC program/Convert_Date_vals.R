

Convert_Date_Vals <- function(input_df, CharDate_Cols, datetime_columns,table_name) {
  result_df <- data.frame()
  result_df1 <- data.frame()
  result_df2 <- data.frame()
  result_df3 <- data.frame()
  result_df1_list <- list()
  result_df2_list <- list()
  
  if (!is.null(CharDate_Cols))
  {
    for (col_name in CharDate_Cols)
    {
      cat('CharDate column name', col_name, 'Type->',str(col_name), "\n")
      sql_query <- paste0(
        
        "	SELECT
    CASE
      WHEN ", col_name, " LIKE '____-__-__' THEN
        substr(", col_name, ", 9, 2) || '-' || 
        CASE
          WHEN substr(", col_name, ", 6, 2) = '01' THEN 'Jan'
          WHEN substr(", col_name, ", 6, 2) = '02' THEN 'Feb'
          WHEN substr(", col_name, ", 6, 2) = '03' THEN 'Mar'
          WHEN substr(", col_name, ", 6, 2) = '04' THEN 'Apr'
          WHEN substr(", col_name, ", 6, 2) = '05' THEN 'May'
          WHEN substr(", col_name, ", 6, 2) = '06' THEN 'Jun'
          WHEN substr(", col_name, ", 6, 2) = '07' THEN 'Jul'
          WHEN substr(", col_name, ", 6, 2) = '08' THEN 'Aug'
          WHEN substr(", col_name, ", 6, 2) = '09' THEN 'Sep'
          WHEN substr(", col_name, ", 6, 2) = '10' THEN 'Oct'
          WHEN substr(", col_name, ", 6, 2) = '11' THEN 'Nov'
          WHEN substr(", col_name, ", 6, 2) = '12' THEN 'Dec'
		      WHEN substr(", col_name, ", 6, 2) = 'UN' THEN 'UNK'
          ELSE ''
        END || '-' || substr(", col_name, ", 1, 4)
        
       WHEN ", col_name, " LIKE '____-__-__ __:__:__' THEN
        substr(", col_name, ", 9, 2) || '-' || 
        CASE
          WHEN substr(", col_name, ", 6, 2) = '01' THEN 'Jan'
          WHEN substr(", col_name, ", 6, 2) = '02' THEN 'Feb'
          WHEN substr(", col_name, ", 6, 2) = '03' THEN 'Mar'
          WHEN substr(", col_name, ", 6, 2) = '04' THEN 'Apr'
          WHEN substr(", col_name, ", 6, 2) = '05' THEN 'May'
          WHEN substr(", col_name, ", 6, 2) = '06' THEN 'Jun'
          WHEN substr(", col_name, ", 6, 2) = '07' THEN 'Jul'
          WHEN substr(", col_name, ", 6, 2) = '08' THEN 'Aug'
          WHEN substr(", col_name, ", 6, 2) = '09' THEN 'Sep'
          WHEN substr(", col_name, ", 6, 2) = '10' THEN 'Oct'
          WHEN substr(", col_name, ", 6, 2) = '11' THEN 'Nov'
          WHEN substr(", col_name, ", 6, 2) = '12' THEN 'Dec'
		      WHEN substr(", col_name, ", 6, 2) = 'UN' THEN 'UNK'
          ELSE ''
        END || '-' || substr(", col_name, ", 1, 4) ||' '||substr(", col_name, ", 12, 5)
      WHEN ", col_name, " LIKE '____-__-UN' THEN
          'UN-' || 
              CASE
          WHEN substr(", col_name, ", 6, 2) = '01' THEN 'Jan'
          WHEN substr(", col_name, ", 6, 2) = '02' THEN 'Feb'
          WHEN substr(", col_name, ", 6, 2) = '03' THEN 'Mar'
          WHEN substr(", col_name, ", 6, 2) = '04' THEN 'Apr'
          WHEN substr(", col_name, ", 6, 2) = '05' THEN 'May'
          WHEN substr(", col_name, ", 6, 2) = '06' THEN 'Jun'
          WHEN substr(", col_name, ", 6, 2) = '07' THEN 'Jul'
          WHEN substr(", col_name, ", 6, 2) = '08' THEN 'Aug'
          WHEN substr(", col_name, ", 6, 2) = '09' THEN 'Sep'
          WHEN substr(", col_name, ", 6, 2) = '10' THEN 'Oct'
          WHEN substr(", col_name, ", 6, 2) = '11' THEN 'Nov'
          WHEN substr(", col_name, ", 6, 2) = '12' THEN 'Dec'
          WHEN substr(", col_name, ", 6, 2) = 'UN' THEN 'UNK'
          ELSE ''
        END || '-' || substr(", col_name, ", 1, 4)
      
      WHEN ", col_name, " LIKE '____-UN-UN' THEN
          'UN'||'-UNK-' || substr(", col_name, ", 1, 4)

      WHEN ", col_name, " LIKE '____-__-__T__:__-__:__' THEN
        substr(", col_name, ", 9, 2) || '-' || 
        CASE
          WHEN substr(", col_name, ", 6, 2) = '01' THEN 'Jan'
          WHEN substr(", col_name, ", 6, 2) = '02' THEN 'Feb'
          WHEN substr(", col_name, ", 6, 2) = '03' THEN 'Mar'
          WHEN substr(", col_name, ", 6, 2) = '04' THEN 'Apr'
          WHEN substr(", col_name, ", 6, 2) = '05' THEN 'May'
          WHEN substr(", col_name, ", 6, 2) = '06' THEN 'Jun'
          WHEN substr(", col_name, ", 6, 2) = '07' THEN 'Jul'
          WHEN substr(", col_name, ", 6, 2) = '08' THEN 'Aug'
          WHEN substr(", col_name, ", 6, 2) = '09' THEN 'Sep'
          WHEN substr(", col_name, ", 6, 2) = '10' THEN 'Oct'
          WHEN substr(", col_name, ", 6, 2) = '11' THEN 'Nov'
          WHEN substr(", col_name, ", 6, 2) = '12' THEN 'Dec'
          WHEN substr(", col_name, ", 6, 2) = 'UN' THEN 'UNK'
          ELSE ''
        END || '-' || substr(", col_name, ", 1, 4) || ' ' || substr(", col_name, ", 12, 5)
      
      WHEN ", col_name, " LIKE '____-__-__TUN:UN:UN.UNKZ' THEN
        substr(", col_name, ", 9, 2) || '-' || 
              CASE
          WHEN substr(", col_name, ", 6, 2) = '01' THEN 'Jan'
          WHEN substr(", col_name, ", 6, 2) = '02' THEN 'Feb'
          WHEN substr(", col_name, ", 6, 2) = '03' THEN 'Mar'
          WHEN substr(", col_name, ", 6, 2) = '04' THEN 'Apr'
          WHEN substr(", col_name, ", 6, 2) = '05' THEN 'May'
          WHEN substr(", col_name, ", 6, 2) = '06' THEN 'Jun'
          WHEN substr(", col_name, ", 6, 2) = '07' THEN 'Jul'
          WHEN substr(", col_name, ", 6, 2) = '08' THEN 'Aug'
          WHEN substr(", col_name, ", 6, 2) = '09' THEN 'Sep'
          WHEN substr(", col_name, ", 6, 2) = '10' THEN 'Oct'
          WHEN substr(", col_name, ", 6, 2) = '11' THEN 'Nov'
          WHEN substr(", col_name, ", 6, 2) = '12' THEN 'Dec'
          WHEN substr(", col_name, ", 6, 2) = 'UN' THEN 'UNK'
          ELSE ''
        END || '-' || substr(", col_name, ", 1, 4) || ' UN:UN'
      
      WHEN ", col_name, " LIKE '____-__-UNTUN:UN:UN.UNKZ' THEN
          'UN-' || 
              CASE
          WHEN substr(", col_name, ", 6, 2) = '01' THEN 'Jan'
          WHEN substr(", col_name, ", 6, 2) = '02' THEN 'Feb'
          WHEN substr(", col_name, ", 6, 2) = '03' THEN 'Mar'
          WHEN substr(", col_name, ", 6, 2) = '04' THEN 'Apr'
          WHEN substr(", col_name, ", 6, 2) = '05' THEN 'May'
          WHEN substr(", col_name, ", 6, 2) = '06' THEN 'Jun'
          WHEN substr(", col_name, ", 6, 2) = '07' THEN 'Jul'
          WHEN substr(", col_name, ", 6, 2) = '08' THEN 'Aug'
          WHEN substr(", col_name, ", 6, 2) = '09' THEN 'Sep'
          WHEN substr(", col_name, ", 6, 2) = '10' THEN 'Oct'
          WHEN substr(", col_name, ", 6, 2) = '11' THEN 'Nov'
          WHEN substr(", col_name, ", 6, 2) = '12' THEN 'Dec'
          WHEN substr(", col_name, ", 6, 2) = 'UN' THEN 'UNK'
          ELSE ''
        END || '-' || substr(", col_name, ", 1, 4) || ' UN:UN'
      
      WHEN ", col_name, " LIKE '____-UN-UNTUN:UN:UN.UNKZ' THEN
          'UN'||'-UNK-' || substr(", col_name, ", 1, 4) || ' UN:UN'
  
      ELSE ", col_name, "
     END AS ",col_name,"
         FROM ", table_name
      )
      cat('Query is ',sql_query)
      result_df1 <- sqldf(sql_query)
      result_df1_list[[col_name]] <- result_df1
      
      cat('CharDate column name end', col_name, "\n")
    } 
    
    
    if (length(result_df1_list) > 0) 
    {
      result_df1 <- do.call(cbind, result_df1_list)
      
    }
    
  }  
  
  if (!is.null(datetime_columns))
  {
    for (col_name in datetime_columns)
    {
      if (col_name %in% names(input_df))
      {
        cat('dATEtIME column name', col_name, "\n")
        
        #if (is.POSIXct(input_df[[col_name]])) {
        
        # input_df[[col_name]] <- format(input_df[[col_name]], "%d-%b-%Y %H:%M:%S")
        #}
        if ("POSIXct" %in% class(input_df[[col_name]]) || "Date" %in% class(input_df[[col_name]]))
        {
          input_df[[col_name]] <- format(input_df[[col_name]], "%d-%b-%Y %H:%M:%S")
        }
        
        result_df2_list[[col_name]] <- input_df[[col_name]]
        result_df2 <- input_df[,datetime_columns]
        cat('dATEtIME column name end', col_name, "\n")
      }
      else
      {
        cat('The column ',col_name ,' is not found in the dataframe ', "\n")
      }
    }
    if (length(result_df2_list) > 0) {
      result_df2 <- do.call(cbind, result_df2_list)
    }
  }
  
  non_char_datetime_cols <- setdiff(colnames(input_df), c(CharDate_Cols, datetime_columns))
  result_df3 <- input_df[, non_char_datetime_cols]
  
  cat('Other columns have been merged ', "\n")
  
  if(nrow(result_df2) == 0){
    print("data.frame is empty")
  }else{
    print("data.frame contains data")
  }
  
  # Combine the dataframes based on conditions
  if (nrow(result_df1) > 0 && nrow(result_df2) > 0 && nrow(result_df3) > 0) {
    cat('Combine df1 & df2 & df3 ', "\n")
    result_df <- cbind(result_df1, result_df2, result_df3)
  } else if (nrow(result_df1) == 0 && nrow(result_df2) == 0 && nrow(result_df3) == 0) {
    cat('Combine df1 & df2 & df3 ', "\n")
    result_df <- cbind(result_df1, result_df2, result_df3)
  }
  
  else if (nrow(result_df1) > 0 && nrow(result_df3) > 0) {
    cat('Combine df1 & df3 ', "\n")
    result_df <- cbind(result_df1, result_df3)
    #result_df <- cbind(result_df1)
  }
  else if (nrow(result_df2) > 0 && nrow(result_df3) > 0) {
    cat('Combine df2 & df3 ', "\n")
    result_df <- cbind(result_df2, result_df3)
  } else if (nrow(result_df1) > 0) {
    cat('Combine df1 ', "\n")
    result_df <- result_df1
  } else if (nrow(result_df2) > 0) {
    cat('Combine df2 ', "\n")
    result_df <- result_df2
  } else if (nrow(result_df3) > 0) {
    cat('Combine df3 ', "\n")
    result_df <- result_df3
  }
  
  
  return(result_df)
}

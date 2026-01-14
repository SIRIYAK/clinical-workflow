data import


jas------------


#################### eCompare Tool
#################### Developed by: Jasmine Khurana
### Jan 2021-22 Project - 23Jan2022
#eCompare Tool will enable flexible intake of data and provide the difference in values to reduce the manual effort of comparing data.
#############################################################


library(shiny)
library(shinydashboard)
library(DT)
library(htmlwidgets)
library(daff)
library(readxl)
library(haven)
library(dplyr)
library(writexl)
library(janitor)
library(stringr)
library(openxlsx)
library(fs)
library(shinyFiles)

options(shiny.maxRequestSize=100*1024^2)  #increasing the file upload limit to 100 MB


differing <- function(old, new, ideal=NULL){
  x <- data.frame()
  y <- data.frame()
  common <- data.frame()
  
  #new part for column consistency. Also, to check missing columns (new and removed columns)
  missing_test1 <- names(new)[!names(new) %in% names(old)]  #new column in new
  
  if(is.na(missing_test1[1]) == FALSE){
    old[,missing_test1] <- "-"   #column not in old
  }
  
  missing_test2 <- names(old)[!names(old) %in% names(new)]  #old column removed from old
  
  if(is.na(missing_test2[1]) == FALSE){
    new[,missing_test2] <- "-"   #column not in new
  }
  ##################################
  
  old <- mutate_all(old, ~replace(., is.na(.), "<empty>"))  #in case of blanks, replace with text "empty"
  new <- mutate_all(new, ~replace(., is.na(.), "<empty>"))
  
  x <- anti_join(old, new, by = ideal) #rows in old that do not have match in new
  if ((dim(x)[1] != 0)){x$daff <- "Removed"
  } 
  
  ##################################
  y <- anti_join(new,old,by=ideal)  #rows in new that do not have match in old
  if ((dim(y)[1] != 0)){y$daff <- "New"
  }
  
  ###################################### common 
  
  old$cats <- do.call(paste0,old[,1:ncol(old)])
  new$cats <- do.call(paste0,new[,1:ncol(new)])
  
  p <- inner_join(new,old,ideal)
  
  if ((dim(p)[1] != 0) & !is.null(ideal)){
    
    #m <- old %>% select(-ideal,-"cats") %>% colnames() %>% paste0(".x")  #storing columnnames of x and y in m and n
    #n <- new %>% select(-ideal,-"cats") %>% colnames() %>% paste0(".y")
    
    #new edited imp
    m <- old %>% select(sort(names(.))) %>% select(-ideal) %>% colnames() %>% paste0(".x")  #storing columnnames of x and y in m and n
    n <- new %>% select(sort(names(.))) %>% select(-ideal) %>% colnames() %>% paste0(".y")
    ###
    
    ev <- p[as.character(m[1:length(m)])] == p[as.character(n[1:length(n)])]  #checking whether x and y are similalr
    
    #stat <- matrix(round((apply(ev,1,sum, na.rm = TRUE)/ncol(ev)),1)) #evaluating extent of similarity
    eval <- apply(ev,1,sum, na.rm = TRUE)
    stat <- as.matrix(round((eval+length(ideal))/(ncol(ev)+length(ideal)),1))   #evaluating extent of similarity
    
    
    colnames(ev) <- gsub(".x","",colnames(ev))  #drop .x
    p <- cbind(p, ev, stat)
    p <- p %>% arrange(desc(stat))  
    infor <- do.call(rbind, lapply(split(p,p$cats.x), head, 1))  #only the highest stat score picked up
    rownames(infor) <- NULL
    
    infor$daff <- "New"   #by deafult everthing as New and then replace based on below loop
    infor$modified_info <- "NA"   #this variable to store which column is modified
    
    for(i in 1:nrow(infor)){
      if(as.numeric(as.character(infor[i,]$stat)) == 1){
        infor[i,]$daff <- "No Change"           
      }
      if(as.numeric(as.character(infor[i,]$stat)) > 0.5 & as.numeric(as.character(infor[i,]$stat)) < 1){
        infor[i,]$daff <- "Modified"
        hop <- infor %>% select(-"cats")  
        infor[i,]$modified_info <- str_c(colnames(hop)[which(hop[i,] == "FALSE")],collapse="*")  #to store which columns got modified
      }
    }
    
    common <- infor %>%  select(ideal,str_subset(colnames(infor), pattern = ".x$"), daff, modified_info, -"cats.x")
    
    colnames(common) <- gsub(".x","",colnames(common))
    
  }
  
  if ((dim(p)[1] != 0) & is.null(ideal)){
    common <- p
    common$daff <- "No Change" 
    common$modified_info <- NULL 
    common$cats <- NULL}
  
  
  ans <- bind_rows(x,y,common) %>%  rename(Compare_status = daff) %>% select(Compare_status, everything())
  
  ###new
  if(is.na(missing_test1[1]) ==  FALSE || is.na(missing_test2[1]) == FALSE){
    ans_len <- ncol(ans)
    empty <- vector(mode = "character", length = ans_len)  #character vector created
    
    t1 <- which(names(ans) %in% missing_test1)
    
    if(length(t1) != 0){
      empty[t1] <- "**NEW_COLUMN**"
    }
    
    t2 <- which(names(ans) %in% missing_test2)
    
    if(length(t2) != 0){
      empty[t2] <- "**REMOVED_COLUMN**"
    }
    
    names(empty) <- names(ans)  #get aligned with final output
    
    f <- bind_rows(empty,ans)
    row.names(f)[1] <- "Column_Status"
    return(f)}
  else{
    return(ans)}
}
###############################################################
ui <-  dashboardPage(
  dashboardHeader(title = "eCOMPARE TOOL", titleWidth = 700),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem(text = "About", tabName = "about", icon=icon("clipboard"),selected=TRUE),
      # menuItem("Data", tabName = "data", icon=icon("database"),fileInput("file1","Upload the file 1"))
      menuItem("Table Import", tabName = "table", icon=icon("table")),
      menuItem("Output", tabName="plot", icon=icon("line-chart"))
    )
  ),
  
  
  dashboardBody(
    # within tabitems(), define the pages for sidebar menu items
    tabItems(
      tabItem(tabName = "about", tags$h1("eCompare Tool V1.0"),
              tags$h6("Developed by : Data and Analytics Team"),
              tags$p(),
              tags$h3(tags$strong(HTML(paste(tags$span(style="color:red", "Disclaimer:This is a NON-REGULATORY tool. Any action taken based on the output generated is dependent
                                  on End user's sole discretion."), sep = "")))),
              tags$p(),
              tags$p("eCompare Tool is used to Compare two input files for updated data. Comparing two data files would give output on what is added/removed/modified/not changed between old and new file.
              Please go through the user manual for more details on the usage of this tool
                  "),
              tags$b("Table Import section:"),
              tags$p("Use this section to upload input files (excel or sas7bdat)"),
              p("Input (Option 1): Excel sheet where Column Headers should always be present in first row and should not be blank. By default, the tool reads first sheet from input excel.
                In case the input file consist of mulitple sheets, then the tool will provide option to end user to select the required sheet for comparison. The tool reads and compares only one sheet from input files at a time"),
              p("Input (Option 2): Data in sas7bdat format can also be compared"),
              tags$b("Output section:"),
              tags$p("Use this section to view both the input files and difference between them"),
              tags$p("Additional Features (optional):"),
              tags$p("Select Columns to Run: Choose the specific columns from the input files for comparison."),
              tags$p("Select Primary Key: Select the key column or set of key columns that contain values which uniquely identifies each row in a table.
                     By default,tool takes all columns as Primary Key"),
              tags$hr(),
              tags$hr(),
              tags$hr(),
              
              
      ),
      
      tabItem(tabName = "table",
              box(width = NULL, status = "primary", solidHeader = TRUE, title="Table",
                  fileInput("file1","Upload the file 1 (Old File)"),
                  helpText("** File 1 would be your Old/Reference file"),
                  br(),
                  fileInput("file2","Upload the file 2 (New file)"),
                  helpText("** File 2 would be your New data file"),
                  br(),
                  # Input: Select separator ----
                  radioButtons(inputId = "sep", label = "Select the Format of Input file",
                               choices = c(Excel_Format = "xl",
                                           SAS_Format = "sas"
                               ),
                               selected = "xl"),
                  conditionalPanel(condition = "input.sep == xl", 
                                   uiOutput("cityControls"),
                                   uiOutput("cityControls2")
                  ),
                  
                  
                  helpText("** Go to Output Tab after Uploading")
                  # tableOutput("table1")
              )
      ),
      tabItem(tabName = "plot", 
              fluidRow(                    
                column(6,uiOutput("selector")), 
                column(3,uiOutput("selectorkey")), 
                column(6,actionButton("act", "Double Click for Difference")),
                
                tabsetPanel(id="tabsin",
                            tabPanel("Old",value="panel3", DTOutput("oldie")),
                            tabPanel("New",value="panel2",DTOutput("newie")),
                            tabPanel("Difference", value="panel1",downloadButton("dl", "Download"),
                                     DT::DTOutput("tb")
                            )
                ))
              
      )
      
    )))

server <- function(input, output, session){
  
  id <- NULL
  
  # volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  # 
  # shinyDirChoose(input, "directory", roots = volumes, session = session, restrictions = system.file(package = "base"))
  # 
  # observe({
  #   cat("\ninput$directory value:\n\n")
  #   print(input$directory)
  # })
  # 
  # folderpath <- function(){
  #   if (is.integer(input$directory)) {
  #     #cat("No directory has been selected (shinyDirChoose)")
  #     id <<- showNotification(paste("No directory has been selected  !!"), duration = 0)
  #   } else {
  #     c <- parseDirPath(volumes, input$directory)
  #   }
  # }
  old <- reactive({
    
    
    if(input$sep == "xl"){ req(input$file1)
      inputfile <- read_excel(input$file1$datapath, col_names = TRUE, sheet = input$var2) }
    if(input$sep == "sas"){req(input$file1)
      inputfile <- read_sas(input$file1$datapath)}
    
    inputfile <- clean_names(inputfile)
    return(inputfile)
    
    
  })
  
  new <- reactive({
    
    if(input$sep == "xl"){ req(input$file2)
      inputfile <- read_excel(input$file2$datapath, col_names = TRUE, sheet = input$var3)}
    if(input$sep == "sas"){req(input$file2)
      inputfile <- read_sas(input$file2$datapath)}
    
    inputfile <- clean_names(inputfile)
    return(inputfile)
    
  })
  
  
  # Create comparison table (reactive as both of its elements are reactive)
  diff <- reactive({
    OLD_1 <- old()
    NEW_1 <- new()
    #columns <- intersect(names(OLD_1),names(NEW_1))
    
    # columns = names(OLD_1)
    
    if (!is.null(input$var)) {
      columns = input$var
      OLD_1 <- OLD_1[,columns,drop=FALSE] %>% mutate_all(as.character)  #for consistency
      NEW_1 <- NEW_1[,columns,drop=FALSE] %>% mutate_all(as.character) 
    }
    else{
      OLD_1 <- OLD_1 %>% mutate_all(as.character)  #for consistency converting all datatype to character
      NEW_1 <- NEW_1 %>% mutate_all(as.character)  #for consistency
    }
    #########################
    
    ############################### EVALUATE OUTPUT ########################
    
    x <- differing(OLD_1,NEW_1,input$key)
    
    
    return(x)
  })
  
  
  ############# new update for dynamic columns############################
  output$selector <- renderUI({
    selectInput("var", "Select Columns to Run: (*It will take common columns from both input files)", as.list(intersect(names(old()),names(new()))),multiple = TRUE)
  })
  
  ############# adding PRIMARY KEY############################
  output$selectorkey <- renderUI({
    selectInput("key", "Select Primary Key: (*Could be 1 or many)", as.list(intersect(names(old()),names(new()))),multiple = TRUE)
  })
  
  
  ######### update for multiple sheets ###########################
  output$cityControls <- renderUI({req(input$file1)
    if(input$sep == "xl"){
      cities <- excel_sheets(input$file1$datapath)
      selectInput("var2","Select Sheet Name for comparison in file1", as.list(cities))}
  })
  
  output$cityControls2 <- renderUI({req(input$file2)
    if(input$sep == "xl"){
      cities2 <- excel_sheets(input$file2$datapath)
      selectInput("var3","Select Sheet Name for comparison in file2", as.list(cities2))}
  })
  
  ###############################################################################
  
  
  
  #################################################### output ######################################  
  output$oldie <- renderDT({     #first tab
    OLD_1 <- old()
    columns = names(OLD_1)
    
    if (!is.null(input$var)) {
      columns = input$var
    }
    OLD_1[,columns,drop=FALSE]
    
  })
  
  output$newie <-  renderDT({  #second tab
    NEW_1 <- new()
    columns = names(NEW_1)
    
    if (!is.null(input$var)) {
      columns = input$var
    }
    NEW_1[,columns,drop=FALSE]
  })
  
  observeEvent(input$act, {   #third tab
    
    showModal(modalDialog(
      title = HTML('<span style="color:#F22C2C; font-size: 20px; font-weight:bold; font-family:sans-serif ">Please Note<span>'),HTML('<span style="color:#F22C2C; font-size: 20px; font-weight:bold; font-family:sans-serif ">eCompare tool is a NON-REGULATORY tool.
      End users discretion is required before taking any action based on the output
      <span>'),strong(),h1(),size = "l",
      footer = modalButton("Accept")
    ))
    
    ####################################### time  progress  #####################
    withProgress(message = 'Hold ON..', value = 0, {
      # Number of times we'll go through the loop
      n <- 7
      for (j in 1:n) {  
        incProgress(1/n, detail = paste("Evaluating..", j , "out of 10"))
        Sys.sleep(0.1)    
      }
    })
    output$dl <- downloadHandler(
      filename = function() { "eCompare.xlsx"},
      content = function(file) {
        saveWorkbook(outputdata(), file = file, overwrite = TRUE)
      }
    )
    output$tb <- DT::renderDT({
      # DT::datatable(diff(),rownames =  FALSE,class = 'hover cell-border stripe',extensions = c('FixedColumns','FixedHeader'),
      #               options = list(
      #                 dom = 't',
      #                 scrollX = TRUE,
      #                 fixedColumns = list(leftColumns = 1), fixedHeader = TRUE
      #               )
      dat <- diff()
      DT::datatable(dat,class = 'hover cell-border stripe', list(scrollX = TRUE)
                    
      ) %>% formatStyle('Compare_status', backgroundColor =styleEqual(c("Modified","New", "Removed","No Change"), c('lightblue', 'yellow','red','gray')) )  %>%
        formatStyle(names(dat),backgroundColor = styleEqual(c("**NEW_COLUMN**","**REMOVED_COLUMN**"),c('yellow','red')) )
    })
  })
  
  
  #observeEvent(input$test, { 
  outputdata <- function(){
    
    t <- diff()
    
    wb <- createWorkbook()
    addWorksheet(wb, "output")
    
    negStyle <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE") #red
    #posStyle <- createStyle(fontColour = "#006100", bgFill = "#C6EFCE") #green
    neutStyle <- createStyle(fontColour = "#FFFFFF", bgFill = "#4F81BD") #blue
    topsStyle <- createStyle(fontColour = "#FFFFFF", bgFill = "#1A33CC")
    yosStyle <- createStyle(fontColour = "#006100", bgFill = "yellow")
    
    writeData(wb, "output",t)
    
    lens <- nrow(t) + 1
    cons <- ncol(t)
    conditionalFormatting(wb, "output", cols = 1, rows = 1:lens, type = "contains", rule = "Removed",style = negStyle)  #red
    conditionalFormatting(wb, "output", cols = 1, rows = 1:lens, type = "contains", rule = "Modified",style = topsStyle )  #green #posStyle
    conditionalFormatting(wb, "output", cols = 1, rows = 1:lens, type = "contains", rule = "No Change",style = neutStyle)  #lightblue
    conditionalFormatting(wb, "output", cols = 1, rows = 1:lens, type = "contains", rule = "New",style = yosStyle)  #yellow
    
    conditionalFormatting(wb, "output", cols = 1:cons, rows = 1:2, type = "contains", rule = "**NEW_COLUMN**",style = yosStyle)  #yellow
    conditionalFormatting(wb, "output", cols = 1:cons, rows = 1:2, type = "contains", rule = "**REMOVED_COLUMN**",style = negStyle)  #red
    
    return(wb)}
  
  
}
shinyApp(ui = ui, server = server)
---------------------------














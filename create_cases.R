library(tidyverse)
library(RSelenium)
library(keyring)
library(lubridate)
library(readxl)


#key_set("idph_username") #set your IDPH web portal username -- only needs to be done once per computer
#key_set("idph_portal")  #set your IDPH web portal password -- only needs to be done once per computer

#Note: IE is preferred browser for INEDSS but requires special drivers for Selenium. 
#Chrome has issues with switching tabs so script will only work with the Firefox browser.

#Set working directory - only needed if you're not working in a project
#setwd("")

#Load all supporting functions
source('inedss selenium functions.R')

#sets probability threshold for when to add a new person (e.g. "no match") on Person Match page
match_prob_low <- 90

#Import test data
testData <- read_csv("testData.csv") %>% distinct()

#Import default values from data dictionary
defaults <- read_excel("Data Dictionary.xlsx") %>% 
  filter(!is.na(Default_Value)) %>%
  filter(INEDSS_Section != "Reporting Source" |  Variable == 'reporterComment') %>%
  select(Variable, Default_Value) 

#Create empty file to store cases saved for manual entry
headers <- testData[0, ]
manual_path <- paste0("Manual Entry Files/Cases for Manual Entry_", Sys.Date(),".csv")
write_csv(headers, manual_path)

#Start server
start_server()

#Log in to INEDSS
login_inedss()

#Start loop to enter cases    ###### ALWAYS RESET BACK TO 1 IF CHANGING######
for (i in 1:nrow(testData)) {
  
  #Subset data frame by row number (as dictated by current loop iteration)
  case <- testData[i, ] 

  #click add/search
  ifVisiblethenClick("th.dataTableNotSelected:nth-child(4)")
  
  #search for patient
  search_name(case$firstName, case$lastName, case$sex, case$dob)
  
  #Seems to freeze here a lot, adding a wait
  Sys.sleep(3)
  
  #Determine if patient match has been found on the page
  matchStatus <- determinePatientMatch(match_prob_low)
  #matchStatus$patientMatchFound <- "no match"   #Line to help if running cases through loop manually, always leave disabled
  
  #Determine if add new person enabled(if not, save for manual entry)
  newPersonDisabled <- try(rD$findElement("css", "input[name = \"addPerson\"]")$getElementAttribute("disabled")[[1]])
  
  #Execute steps based on whether patient match found
  if (matchStatus$patientMatchFound == "match") {  ### Person exists in INEDSS ###
    
    #Click patient name
    click(paste0("#container > div:nth-child(4) > form:nth-child(3) > table:nth-child(2) > tbody:nth-child(1) > tr:nth-child(4) > td:nth-child(1) > table:nth-child(6) > tbody:nth-child(1) > tr:nth-child(",matchStatus$row,") > td:nth-child(2) > a:nth-child(1)"))
    
    #Determine if previously reported COVID case or out of jurisidiction
    caseRow <- determine_case_match()
    
    #If patient is currently out of jurisdiction, write to CSV for manual entry/follow up
    if(!is.na(caseRow) & caseRow == "OOJ") {
      
      #write patient to csv to flag for manual entry     
      write_csv(case, manual_path, append = T)
      
      #Return to dashboard
      click("th.dataTableNotSelected:nth-child(1) > a:nth-child(1)")
      
      #Skip rest of script and move to next iteration of loop
      next
      
    }
    
    #If in jurisidiction and previously reported COVID, add new lab
    if (!is.na(caseRow)) {
      
      #For now, if case completed, exit without entering lab so case doesn't need to be retracted
      #If reinfection parameters defined, will need to adjust this step
      investigationStatus <- get_text(paste0(".indessTable > tbody:nth-child(1) > tr:nth-child(", caseRow,") > td:nth-child(5)"))
      if (grepl("Completed|Closed", investigationStatus)) {
        
        #Return to dashboard
        click("th.dataTableNotSelected:nth-child(1) > a:nth-child(1)")
        
        #Skip rest of script and move to next iteration of loop
        next
      }
      
      #Click into disease
      click(paste0(".indessTable > tbody:nth-child(1) > tr:nth-child(", caseRow, ") > td:nth-child(1) > a:nth-child(1)"))
      
      #Open all case details
      isPageLoaded(".pageDesc")
      click("fieldset.fieldsetHeader:nth-child(6) > table:nth-child(2) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)")
      
      #Add lab
      enter_lab_data()
      
      #Close case details
      click("input[name=\"closebottom\"]")
      #click("input[name=\"cancel\"]")
      
      
    } else { #if not previous COVID, add new case
      
      click("input[name=\"addCase\"]")
      
      #Select disease
      diseaseErrorCheck <- select_disease(newperson = FALSE)
      
      #Enter new case
      enter_new_case()
      
    } #if/else for match found, previous covid or not
    
    
  } else if (matchStatus$patientMatchFound == "unclear" | newPersonDisabled== "true") {   ### Unable to determine ###
    
    #write patient to csv to flag for manual entry     
    write_csv(case, manual_path, append = T)
    
    #Return to dashboard
    click("th.dataTableNotSelected:nth-child(1) > a:nth-child(1)")
    
    
  } else if (matchStatus$patientMatchFound == "no match") {  ### New person ###
    
    #Click add new person
    click("input[name = \"addPerson\"]")
    
    #Enter demographics
    enter_demographics()
    
    #Select disease
    diseaseErrorCheck <- select_disease(newperson = TRUE)  
    
    #Check to make sure correct disease selected
    if (diseaseErrorCheck == "error") {
      stop("Incorrect disease selected. Update CSS selector.")
    }
    
    #Always save default option on address validation
    #Will likely need is page loaded here
    click("input[name=\"save\"]")
    
    #Enter new case
    enter_new_case()
  
    
    ####FOR TESTING PHASE ONLY####
    #Run lines below to open all case details and case in R to review and ensure data entered correctly
    #Disable chunk when testing complete
    # click("fieldset.fieldsetHeader:nth-child(6) > table:nth-child(2) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)")
    # click("#fullCaseDiv")
    # case %>% View()
    #click("input[name=\"closebottom\"]")
    #i <- i + 1
    ####FOR TESTING PHASE ONLY####
    
    
  } #if/else patient match closure
  
  
  
} #loop closure


#Lines to import data if running saved cases back through the loop manually
#testData <- read_csv(manual_path)

#end session
stop_server()

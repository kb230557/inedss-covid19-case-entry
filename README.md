These scripts are designed to be used by local health department case investigators in Illinois. The scripts use the R Selenium package to mimic a case investigator entering new COVID-19 cases into I-NEDSS. They are specifically intended to assist with case entry from healthcare providers who are using the Abbott ID Now rapid test and who are not able to establish electronic data feeds to IDPH.

Before using these scripts, please review the Data Dictionary and Expected Data Structure files. Data submitted from healthcare providers must be cleaned according to these guidelines and stored with the correct column headers and order. Additional important notes on data cleaning can be found in 'clean data files.Rmd'.

Cleaned data can then be imported and entered into I-NEDSS by running 'create_cases.R'. Support functions for this script are stored in 'inedss selenium functions.R'.  

The script will first search for individuals using name, DOB, and sex. Individuals where the highest probability match returned is below 90% will be added as a "new person" in INEDSS (this threshold can be adjusted at the beginning of the script). Individuals where the highest probability match is 100% (or an exact match based on name and DOB is found in the first three returned suggestions) will be selected and either a new COVID case or new COVID lab (if case already exists) will be added. For remaining individuals where a match (or lack thereof) can't be determined, case data will be saved in a CSV for later manual entry. 

We highly recommend testing and reviewing to ensure cases have been entered correctly on a sample of results from all new providers.

Questions on these scripts should be directed to kbemis@cookcountyhhs.org.

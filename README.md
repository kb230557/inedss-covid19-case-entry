These scripts are designed to be used by local health department case investigators in Illinois. The scripts use the R Selenium package to mimic a case investigator entering new COVID-19 cases into I-NEDSS. They are specifically intended to assist with case entry from healthcare providers who are using the Abbott ID Now rapid test and who are not able to establish electronic data feeds to IDPH. 

Before using these scripts, please review the Data Dictionary and Expected Data Structure files. Data submitted from healthcare providers must be cleaned according to these guidelines and stored with the correct column headers and order. Additional important notes on data cleaning can be found in 'clean data files.Rmd'.

Cleaned data can then be imported and entered into I-NEDSS by running 'create_cases.R'. Support functions for this script are stored in 'inedss selenium functions.R'.  The script will only enter cases for people who do not already exist in I-NEDSS (whether reported for COVID or another disease) - this is determined by the highest probability returned after searching for an individual. If a probability match is returned that is > 80%, case data will be saved in a CSV for manual entry. This threshold can be adjusted at the beginning of the script.

We highly recommend testing and reviewing to ensure cases have been entered correctly on a sample of results from all new providers.

Questions on these scripts should be directed to kbemis@cookcountyhhs.org.

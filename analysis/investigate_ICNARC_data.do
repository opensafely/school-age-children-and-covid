/*==============================================================================
DO FILE NAME:			investigate_ICNARC_data
PROJECT:				Exposure children and COVID risk
DATE: 					25th June 2020 
AUTHOR:					Harriet Forbes adapted from A Wong, A Schultze, C Rentsch,
						 K Baskharan, E Williamson 										
DESCRIPTION OF FILE:	tab numbers admitted to ICU for COVID overall, by age and sex
DATASETS USED:			analysis_dataset
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
							
==============================================================================*/

* Open a log file
cap log close
log using $logdir/investigate_ICNARC_data, replace t

use $tempdir/analysis_dataset, clear

sum covid_icu_date, d f

*Overall numbers
tab covid_icu

*By sex
tab covid_icu male, col chi

*By age
tab covid_icu agegroup, col chi

*By month
gen mo_icu_adm=month(covid_icu_date)
lab define mo_icu_adm 2 Feb 3 March 4 April 5 May 6 June 7 July 8 August
lab val mo_icu_adm mo_icu_adm
tab mo_icu_adm

*By positive covid test
tab covid_icu   positive_covid_test_ever, col chi

*By death
tab covid_icu  covid_death, col chi


log close


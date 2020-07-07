********************************************************************************
*
*	Do-file:		EXPLORE_covid_death_ITU_sex_age.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	HFORBES based on Elizabeth Williamson
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file: output/EXPLORE_covid_death_ITU_sex_age.log
*
********************************************************************************
*
*	Purpose:		This do-file runs some basic tabulations on the analysis
*					dataset.
*  
********************************************************************************


* Open a log file
capture log close
log using "$logdir\EXPLORE_covid_death_ITU_sex_age", replace t

use $tempdir\analysis_dataset, clear

tab covid_death_itu

tab covid_death_itu agegroup, col chi

tab covid_death_itu male, col chi

log close

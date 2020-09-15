*Model do file

*When running in parallel locally use "C:/Program Files (x86)/Stata15/Stata-64.exe"
*When running on server use "c:/program files/stata16/statamp-64.exe"


***********************HOUSE-KEEPING*******************************************

set more off

* Set globals
global codedir "`c(pwd)'/analysis"
global outdir  	  "`c(pwd)'/output"
global logdir     "`c(pwd)'/log"
global tempdir    "`c(pwd)'/tempdata"

* Create directories required
capture mkdir "$outdir"
capture mkdir "$logdir"
capture mkdir "$tempdir"

********************************************************************************

*  Pre-analysis data manipulation  *
do "$codedir/01_cr_analysis_dataset.do"

/*  Checks  */
do "$codedir/02_an_data_checks.do"


*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************

do "$codedir/03a_an_descriptive_tables.do"
do "$codedir/03b_an_descriptive_table_1.do" 

do "$codedir/04a_an_descriptive_tables.do"

do "$codedir/04b_an_descriptive_table_2.do" non_covid_death
do "$codedir/04b_an_descriptive_table_2.do" covid_tpp_prob
do "$codedir/04b_an_descriptive_table_2.do" covidadmission
do "$codedir/04b_an_descriptive_table_2.do" covid_icu
do "$codedir/04b_an_descriptive_table_2.do" covid_death

*winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/05_an_descriptive_plots.do"


*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/06_univariate_analysis.do" `outcome' ///
		kids_cat3  ///
		gp_number_kids
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/06a_univariate_analysis_SENSE_12mo"  `outcome' ///
		kids_cat3 
}

*Pause for 4 hours
forvalues i = 1/10 {
    di `i'
    sleep 10000
}
*pause Stata for 4 hours: 1/1440 whilst testing on server, on full data

************************************************************
*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07a_an_multivariable_cox_models_demogADJ.do" `outcome'
}
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07b_an_multivariable_cox_models_FULL.do" `outcome'
}	

*Pause for 4 hours
forvalues i = 1/10 {
    di `i'
    sleep 10000
}
*pause Stata for 4 hours: 1/1440 whilst testing on server, on full data

***SENSE ANALYSES - 9 hours (45 hours)
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07b_an_multivariable_cox_models_FULL_Sense1.do" `outcome'
}
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07b_an_multivariable_cox_models_FULL_Sense2.do" `outcome'
}

*Pause for 6 hours
forvalues i = 1/10 {
    di `i'
    sleep 10000
}
*pause Stata for 6 hours: 1/2160 whilst testing on server, on full data


foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07b_an_multivariable_cox_models_FULL_Sense3.do" `outcome'
}
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07b_an_multivariable_cox_models_FULL_Sense4.do" `outcome'
}

*Pause for 6 hours
forvalues i = 1/10 {
    di `i'
    sleep 10000
}
*pause Stata for 6 hours: 1/2160 whilst testing on server, on full data



foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/07b_an_multivariable_cox_models_FULL_Sense5.do" `outcome'
}

*EXPLORATORY ANALYSIS: restricting to single adult hh
foreach outcome of any   non_covid_death covid_tpp_prob covid_death covid_icu covidadmission  {
winexec "c:/program files/stata16/statamp-64.exe" 	do "$codedir/16_exploratory_analysis.do" `outcome'
}
************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************


/**MULTIPLE IMPUTAION: create the datasets (~3 hours each outcome)
foreach outcome of any covid_tpp_prob covidadmission covid_icu covid_death  {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/13_multiple_imputation_dataset.do" `outcome'
	} 
	
**MULTIPLE IMPUTAION: run (~20 hours each outcome - 80 hours)
foreach outcome of any covid_tpp_prob covidadmission covid_icu covid_death  {
winexec "c:/program files/stata16/statamp-64.exe" do "$codedir/14_multiple_imputation_analysis.do" `outcome'
}*/

*Pause for 6 hours
forvalues i = 1/10 {
    di `i'
    sleep 10000
}
*pause Stata for 6 hours: 1/2160 whilst testing on server, on full data


*INTERACTIONS (7 hours each - 140)
*Sex
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe"  do "$codedir/10_an_interaction_cox_models_sex" `outcome'	
}
*Shield
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe"  do "$codedir/10_an_interaction_cox_models_shield" `outcome'	
}

*Pause for 6 hours
forvalues i = 1/10 {
    di `i'
    sleep 10000
}
*pause Stata for 6 hours: 1/2160 whilst testing on server, on full data


*Time
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe"  do "$codedir/10_an_interaction_cox_models_time" `outcome'	
}
*Weeks
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
winexec "c:/program files/stata16/statamp-64.exe"  do "$codedir/10_an_interaction_cox_models_weeks" `outcome'	
}




*********************************************************************
*		WORMS ANALYSIS CONTROL OUTCOME REQUIRES NEW STUDY POP		*
*********************************************************************	

set more off 

/*  Pre-analysis data manipulation  */
do "$codedir/WORMS_01_cr_analysis_dataset.do"

/*  Checks  */
do "$codedir/WORMS_02_an_data_checks.do"

*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************


*Univariate models can be run in parallel Stata instances for speed
*Command is "do an_univariable_cox_models <OUTCOME> <VARIABLE(s) TO RUN>
*The following breaks down into 4 batches, 
*  which can be done in separate Stata instances
*Can be broken down further but recommend keeping in alphabetical order
*   because of the ways the resulting log files are named

*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)

foreach outcome of any worms {
winexec "c:/program files/stata16/statamp-64.exe" 	do "$codedir/WORMS_06_univariate_analysis.do" `outcome' ///
		kids_cat3  ///
		gp_number_kids
		
************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
winexec "c:/program files/stata16/statamp-64.exe" 	do "$codedir/WORMS_07a_an_multivariable_cox_models_demogADJ.do" `outcome'
winexec "c:/program files/stata16/statamp-64.exe" 	do "$codedir/WORMS_07b_an_multivariable_cox_models_FULL.do" `outcome'
}	


************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************
*Pause for 2 hours
forvalues i = 1/5 {
    di `i'
    sleep 10000
}
*pause Stata for 2 hours: 1/720 whilst testing on server, on full data

*Tabulate results
foreach outcome of any  non_covid_death covid_tpp_prob covid_death covid_icu covidadmission   {
	do "$codedir/08_an_tablecontent_HRtable.do" `outcome'
}


*put results in figure
do "$codedir/15_anHRfigure_all_outcomes.do"


foreach outcome of any worms  {
	do "$codedir/WORMS_08_an_tablecontent_HRtable.do" `outcome'
}


foreach outcome of any  non_covid_death covid_tpp_prob covidadmission covid_icu covid_death     {
	do "$codedir/11_an_interaction_HR_tables_forest.do" 	 `outcome'
}

do "$codedir/11a_an_interaction_HR_tables_forest_WEEKS.do"

*do "$codedir/FOREST_interactions.do"

foreach outcome of any  covid_tpp_prob covidadmission covid_icu covid_death   {
	do "$codedir/09_an_agesplinevisualisation.do" `outcome'
}

***SENSE ANALYSIS
foreach outcome of any covid_tpp_prob covidadmission covid_icu covid_death    {
	do "$codedir/12_an_tablecontent_HRtable_SENSE.do" `outcome'
	}

	

	

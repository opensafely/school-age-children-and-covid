*Model do file

*When running in parallel locally use "C:\Program Files (x86)\Stata15\stata-64.exe"
*When running on server use "c:\program files\stata16\statamp-64.exe"


*Import dataset into STATA
import delimited `c(pwd)'/output/input.csv, clear

cd  `c(pwd)'/analysis /*sets working directory to workspace folder*/
set more off 

***********************HOUSE-KEEPING*******************************************
* Create directories required 
capture mkdir output
capture mkdir log
capture mkdir tempdata


* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"
global demogadjlist  age1 age2 age3 i.male	`bmi' `smoking'	`ethnicity'	i.imd i.tot_adults_hh
global comordidadjlist  i.htdiag_or_highbp				///
			i.chronic_respiratory_disease 	///
			i.asthma						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.esrd							///
			i.other_transplant 				///
			i.asplenia 						///
			i.ra_sle_psoriasis  			///
			i.other_immuno					

********************************************************************************


/*  Pre-analysis data manipulation  */
do "01_cr_analysis_dataset.do"

/*  Checks  */
do "02_an_data_checks.do"


*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************

winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "03a_an_descriptive_tables.do"
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "03b_an_descriptive_table_1.do" 

winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "04a_an_descriptive_tables.do"

foreach outcome of any  covid_death_icu non_covid_death      {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "04b_an_descriptive_table_2.do" `outcome'
	}
	
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "05_an_descriptive_plots.do"


*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)
foreach outcome of any  covid_death_icu non_covid_death      {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "06_univariate_analysis.do" `outcome' ///
		kids_cat3  ///
		gp_number_kids
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "06a_univariate_analysis_SENSE_12mo"  `outcome' ///
		kids_cat3 
}


************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
foreach outcome of any  covid_death_icu non_covid_death      {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07a_an_multivariable_cox_models_demogADJ.do" `outcome'
}
foreach outcome of any  covid_death_icu non_covid_death      {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07b_an_multivariable_cox_models_FULL.do" `outcome'
}		



foreach outcome of any  covid_death_icu non_covid_death   {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07b_an_multivariable_cox_models_FULL_Sense1.do" `outcome'
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07b_an_multivariable_cox_models_FULL_Sense2.do" `outcome'
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07b_an_multivariable_cox_models_FULL_Sense3.do" `outcome'
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07b_an_multivariable_cox_models_FULL_Sense4.do" `outcome'
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" do "07b_an_multivariable_cox_models_FULL_Sense5.do" `outcome'
}


************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************

*INTERACTIONS
/*Age - now startifying on age
foreach outcome of any  covid_death_icu     {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe"  do "10_an_interaction_cox_models_age" `outcome'	
}*/
*Sex
foreach outcome of any  covid_death_icu     {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe"  do "10_an_interaction_cox_models_sex" `outcome'	
}
*Shield
foreach outcome of any  covid_death_icu     {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe"  do "10_an_interaction_cox_models_shield" `outcome'	
}
*Time
foreach outcome of any  covid_death_icu     {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe"  do "10_an_interaction_cox_models_time" `outcome'	
}




/*EXPLORATORY ANALYSIS: prop hazards investigation
foreach outcome of any  covid_death_icu non_covid_death  {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" 	do "16_exploratory_analysis.do" `outcome'
}*/

*********************************************************************
*		WORMS ANALYSIS CONTROL OUTCOME REQUIRES NEW STUDY POP		*
*       															*
*********************************************************************	

cd ..
import delimited `c(pwd)'/output/input_worms.csv, clear

cd  `c(pwd)'/analysis /*sets working directory to workspace folder*/
set more off 

/*  Pre-analysis data manipulation  */
do "WORMS_01_cr_analysis_dataset.do"

/*  Checks  */
do "WORMS_02_an_data_checks.do"

*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************

do "WORMS_03a_an_descriptive_tables.do"
do "WORMS_03b_an_descriptive_table_1.do" 


do "WORMS_04a_an_descriptive_tables.do"
foreach outcome of any worms {
do "WORMS_04b_an_descriptive_table_2.do" `outcome'
	}


*Univariate models can be run in parallel Stata instances for speed
*Command is "do an_univariable_cox_models <OUTCOME> <VARIABLE(s) TO RUN>
*The following breaks down into 4 batches, 
*  which can be done in separate Stata instances
*Can be broken down further but recommend keeping in alphabetical order
*   because of the ways the resulting log files are named

*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)

foreach outcome of any worms {
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" 	do "WORMS_06_univariate_analysis.do" `outcome' ///
		kids_cat3  ///
		gp_number_kids
		
************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" 	do "WORMS_07a_an_multivariable_cox_models_demogADJ.do" `outcome'
winexec "C:\Program Files (x86)\Stata15\stata-64.exe" 	do "WORMS_07b_an_multivariable_cox_models_FULL.do" `outcome'
}	


************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************
forvalues i = 1/360 {
    di `i'
    sleep 10000
}
*pauses Stata for 4 minutes: 1/24 whilst testing locally
*pauses Stata for 10 mins: 1/360 whilst testing on server, on 5% weighted data
*pauses Stata for 12 hours: 1/4320 whilst testing on server, on full data

*Tabulate results
foreach outcome of any  covid_death_icu non_covid_death      {
	do "08_an_tablecontent_HRtable.do" `outcome'
}

foreach outcome of any  covid_death_icu      {
	do "11_an_interaction_HR_tables_forest.do" 	 `outcome'
}

foreach outcome of any  covid_death_icu   {
	do "09_an_agesplinevisualisation.do" `outcome'
}



foreach outcome of any worms  {
	do "WORMS_08_an_tablecontent_HRtable.do" `outcome'
}


foreach outcome of any  covid_death_icu {
do "13_multiple_imputation_dataset.do" `outcome'
	}

foreach outcome of any  covid_death_icu {
do "14_multiple_imputation_analysis.do" `outcome'
}

***SENSE ANALYSIS
foreach outcome of any  covid_death_icu      {
	do "12_an_tablecontent_HRtable_SENSE.do" `outcome'
	}

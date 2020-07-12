*Model do file

*Import dataset into STATA
import delimited `c(pwd)'/output/input.csv, clear

cd  `c(pwd)'/analysis /*sets working directory to analysis folder*/
set more off 

***********************HOUSE-KEEPING*******************************************
* Create directories required 
capture mkdir analysis\output
capture mkdir analysis\log
capture mkdir analysis\tempdata


* Set globals that will print in programs and direct output
global outdir  	  ".\analysis\output" 
global logdir     ".\analysis\log"
global tempdir    ".\analysis\tempdata"

********************************************************************************

/*  Pre-analysis data manipulation  */
do ".\analysis\01_cr_analysis_dataset.do"

/*  Checks  */
do ".\analysis\02_an_data_checks.do"


*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************

do ".\analysis\03a_an_descriptive_tables.do"
do ".\analysis\03b_an_descriptive_table_1.do" 


do ".\analysis\04a_an_descriptive_tables.do"
foreach outcome of any covid_tpp_prob covid_death_itu covid_tpp_prob_or_susp {
do ".\analysis\04b_an_descriptive_table_2.do" `outcome'
	}
	
do ".\analysis\05_an_descriptive_plots.do"


*Univariate models can be run in parallel Stata instances for speed
*Command is "do an_univariable_cox_models <OUTCOME> <VARIABLE(s) TO RUN>
*The following breaks down into 4 batches, 
*  which can be done in separate Stata instances
*Can be broken down further but recommend keeping in alphabetical order
*   because of the ways the resulting log files are named

*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)

foreach outcome of any covid_tpp_prob covid_death_itu covid_tpp_prob_or_susp {
	do ".\analysis\06_univariate_analysis.do" `outcome' ///
		kids_cat3  ///
		gp_number_kids
	do ".\analysis\06a_univariate_analysis_SENSE_12mo"  `outcome' ///
		kids_cat3 
************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
	do ".\analysis\07a_an_multivariable_cox_models_demogADJ.do" `outcome'
	do ".\analysis\07b_an_multivariable_cox_models_FULL.do" `outcome'
}	

************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************
foreach outcome of any covid_tpp_prob covid_tpp_prob_or_susp covid_death_itu  {
	do ".\analysis\08_an_tablecontent_HRtable_HRforest.do" `outcome'
}	


foreach outcome of any covid_tpp_prob covid_tpp_prob_or_susp covid_death_itu  {
	do ".\analysis\09_an_agesplinevisualisation.do" `outcome'
}

*INTERACTIONS
*Create models
foreach outcome of any covid_tpp_prob covid_death_itu {
do ".\analysis\10_an_interaction_cox_models" `outcome'	
}

*Tabulate results
foreach outcome of any covid_tpp_prob covid_death_itu {
	do ".\analysis\11_an_interaction_HR_tables_forest.do" 	 `outcome'
}


***SENSE ANALYSIS
*CC ETH
foreach outcome of any covid_tpp_prob covid_death_itu {
	do ".\analysis\12_an_tablecontent_HRtable_SENSE_ADD_ETH_BMI_SMOK_CC.do" `outcome'
	}

*CC ETH BMI SMOK
foreach outcome of any covid_tpp_prob covid_death_itu {
	do ".\analysis\13_an_tablecontent_HRtable_SENSE_ADD_ETHNICITY.do" `outcome'
	}

*DROP IF <12M FUP
foreach outcome of any covid_tpp_prob covid_death_itu {
	do ".\analysis\14_an_tablecontent_HRtable_HRforest_SENSE_12mo.do" `outcome'
	}

*CC BMI SMOK (not includ. ethnicity)
foreach outcome of any covid_tpp_prob covid_death_itu {
	do ".\analysis\15_an_tablecontent_HRtable_HRforest_SENSE_CC_noeth_bmi_smok.do"  `outcome'
	}
	
	
	
*********************************************************************
*		WORMS ANALYSIS CONTROL OUTCOME REQUIRES NEW STUDY POP		*
*       															*
*********************************************************************	
	
*Import dataset into STATA
import delimited `c(pwd)'/output/input_worms.csv, clear

*cd  `c(pwd)'/analysis /*sets working directory to analysis folder*/
set more off 

/*  Pre-analysis data manipulation  */
do ".\analysis\WORMS_01_cr_analysis_dataset.do"

/*  Checks  */
do ".\analysis\WORMS_02_an_data_checks.do"

*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************

do ".\analysis\WORMS_03a_an_descriptive_tables.do"
do ".\analysis\WORMS_03b_an_descriptive_table_1.do" 


do ".\analysis\WORMS_04a_an_descriptive_tables.do"
foreach outcome of any worms {
do ".\analysis\WORMS_04b_an_descriptive_table_2.do" `outcome'
	}
	
do ".\analysis\WORMS_05_an_descriptive_plots.do"


*Univariate models can be run in parallel Stata instances for speed
*Command is "do an_univariable_cox_models <OUTCOME> <VARIABLE(s) TO RUN>
*The following breaks down into 4 batches, 
*  which can be done in separate Stata instances
*Can be broken down further but recommend keeping in alphabetical order
*   because of the ways the resulting log files are named

*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)

foreach outcome of any worms {
	do ".\analysis\WORMS_06_univariate_analysis.do" `outcome' ///
		kids_cat3  ///
		gp_number_kids
		
************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
	do ".\analysis\WORMS_07a_an_multivariable_cox_models_demogADJ.do" `outcome'
	do ".\analysis\WORMS_07b_an_multivariable_cox_models_FULL.do" `outcome'
}	

************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************
foreach outcome of any worms  {
	do ".\analysis\WORMS_08_an_tablecontent_HRtable_HRforest.do" `outcome'
}	

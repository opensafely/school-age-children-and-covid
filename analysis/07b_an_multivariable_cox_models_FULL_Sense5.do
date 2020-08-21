********************************************************************************
*
*	Do-file:		07b_an_multivariable_cox_models_Sense5.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file:  07b_an_multivariable_cox_models_`outcome'.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models, with time interactions
*  
********************************************************************************
*	
*	Stata routines needed:	stbrier	  
*
********************************************************************************

* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"


local outcome `1' 


************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************

* Open a log file
capture log close
log using "$logdir\07b_an_multivariable_cox_models_`outcome'_Sense5_time_ints", text replace


******************************
*  Multivariable Cox models  *
******************************
use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_0.dta", clear
*make vars binary
gen anyreduced_kidney_function = reduced_kidney_function_cat>=2
gen anyobesity = obese4cat>=2
gen highimd = imd>=3
gen anydiab= diabcat>=2

stsplit timeperiod, at(60 90)

*Age and sex adjusted
stcox i.kids_cat3 age1 age2 age3 i.male, strata(stp) vce(cluster household_id)
estimates
estimates save ./output/an_univariable_cox_models_`outcome'_AGESEX_time_int_ageband_0, replace						

*Minimally adjusted
stcox 	i.kids_cat3 	///
			age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 						///
		60.timeperiod#1.anyobesity							///
			90.timeperiod#1.anyobesity						///
		60.timeperiod#3.smoke_nomiss						///
			90.timeperiod#3.smoke_nomiss					///
		60.timeperiod#1.highimd								///
			90.timeperiod#1.highimd							///
			, strata(stp) vce(cluster household_id)
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_kids_cat3_DEMOGADJ_time_int_ageband_0, replace
estat phtest, d


*Fully adjusted
 stcox 	i.kids_cat3 	 ///
			age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 						///
			`comordidadjlist'	///	
		60.timeperiod#1.anyobesity							///
			90.timeperiod#1.anyobesity						///
		60.timeperiod#3.smoke_nomiss						///
			90.timeperiod#3.smoke_nomiss					///
		60.timeperiod#1.highimd								///
			90.timeperiod#1.highimd							///
		60.timeperiod#1.anydiab					///
			90.timeperiod#1.anydiab					///		
		60.timeperiod#1.chronic_liver_disease				///
			90.timeperiod#1.chronic_liver_disease			///
		60.timeperiod#1.cancer_exhaem_cat					///
			90.timeperiod#1.cancer_exhaem_cat				///
		60.timeperiod#1.asplenia						///
			90.timeperiod#1.asplenia						///
		60.timeperiod#1.other_immuno						///
			90.timeperiod#1.other_immuno					///
			, strata(stp) vce(cluster household_id)
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_kids_cat3_MAINFULLYADJMODEL_time_int_ageband_0, replace
estat phtest, d


******************************
*  Multivariable Cox models  *
******************************
use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_1.dta", clear
stsplit timeperiod, at(60 90)

*make vars binary
gen anyreduced_kidney_function = reduced_kidney_function_cat>=2
gen anyobesity = obese4cat>=2
gen highimd = imd>=3
gen anydiab= diabcat>=2
*Age and sex adjusted
stcox i.kids_cat3 age1 age2 age3 i.male, strata(stp) vce(cluster household_id)
estimates
estimates save ./output/an_univariable_cox_models_`outcome'_AGESEX_time_int_ageband_1, replace						

*Minimally adjusted
stcox 	i.kids_cat3 	///
			age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 						///
		60.timeperiod#1.male							///
			90.timeperiod#1.male						///
			, strata(stp) vce(cluster household_id)
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_kids_cat3_DEMOGADJ_time_int_ageband_1, replace
estat phtest, d



*Fully adjusted
stcox 	i.kids_cat3 	 ///
			age1 age2 age3		///
			i.male 							///
			i.obese4cat 					///
			i.smoke_nomiss					///
			i.imd 						///
			`comordidadjlist'	///	
		60.timeperiod#1.male							///
			90.timeperiod#1.male						///
		60.timeperiod#3.anyreduced_kidney_function						///
			90.timeperiod#3.anyreduced_kidney_function					///
			, strata(stp) vce(cluster household_id)
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_kids_cat3_MAINFULLYADJMODEL_time_int_ageband_1, replace

estat phtest, d


log close



exit, clear STATA


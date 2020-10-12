********************************************************************************
*
*	Do-file:		WORMS_07a_an_multivariable_cox_models_demogADJ.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file:  WORMS_07a_an_multivariable_cox_models_demogADJ.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models. 
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
cap erase ./output/an_multivariate_cox_models_`outcome'_DEMOGADJ_agespline_bmicat_noeth.ster
cap erase ./output/an_multivariate_cox_models_`outcome'_DEMOGADJ_agegroup_bmicat_noeth.ster
cap erase ./output/an_multivariate_cox_models_`outcome'_DEMOGADJ_agespline_bmicat_CCeth.ster
cap erase ./output/an_multivariate_cox_models_`outcome'_DEMOGADJ_agespline_bmicat_CCnoeth.ster


* Open a log file
capture log close
log using "$logdir/WORMS_07a_an_multivariable_cox_models_demogADJ_`outcome'", text replace


******************************
*  Multivariable Cox models  *
******************************

*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , exposure(string) age(string) [ethnicity(real 1) if(string)] bmi(string) smoking(string)

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	capture stcox 	`exposure' `age' 					///
			i.male 							///
			`bmi'					///
			`smoking'					///
			`ethnicity'						///
			i.imd 							///
			i.tot_adults_hh				///
			`if'							///
			, strata(stp) vce(cluster household_id)
timer off 1
timer list
end
*************************************************************************************



* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir/cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear


foreach exposure_type in kids_cat3 gp_number_kids {

*Age spline model (not adj ethnicity)
basecoxmodel, exposure("i.`exposure_type'") age("age1 age2 age3")  ethnicity(1) bmi(i.obese4cat) smoking(i.smoke_nomiss)
if _rc==0{
estimates
estimates save ./output/an_multivariate_cox_models_`outcome'_`exposure_type'_DEMOGADJ_noeth_ageband_`x', replace
*estat concordance /*c-statistic*/
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"

}
}

log close
exit, clear STATA

********************************************************************************
*
*	Do-file:		06a_univariate_analysis_SENSE_12mo.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	Hforbes, based on files from Fizz & Krishnan
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file: an_univariable_cox_models.log 
*
********************************************************************************
*
*	Purpose:		Fit age/sex adjusted Cox models, stratified by STP and 
*with hh size as random effect.  Restrict population to those with 12 months
*follow-up
*  
********************************************************************************

* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"


*PARSE DO-FILE ARGUMENTS (first should be outcome, rest should be variables)
local arguments = wordcount("`0'") 
local outcome `1'
local varlist
forvalues i=2/`arguments'{
	local varlist = "`varlist' " + word("`0'", `i')
	}
local firstvar = word("`0'", 2)
local lastvar = word("`0'", `arguments')
	

* Open a log file
capture log close
log using "$logdir\06a_univariate_analysis_SENSE_12mo`outcome'", replace t

* Open dataset and fit specified model(s)
forvalues x=0/1 {

use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'_ageband_`x'.dta", clear

*SENSITIVITY ANALYSIS: 12 months FUP
drop if has_12_m_follow_up == .
foreach var of any `varlist' {

	*General form of model
	else local model "age1 age2 age3 i.male i.`var'"

	*Fit and save model
	cap erase ./output/an_univariable_cox_models_`outcome'_AGESEX_`var'_12mo.ster
	capture stcox `model' , strata(stp) vce(cluster household_id)
	if _rc==0 {
		estimates
		estimates save ./output/an_univariable_cox_models_`outcome'_AGESEX_`var'_12mo_ageband_`x'.ster, replace
		}
	else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"

}

}
* Close log file
log close

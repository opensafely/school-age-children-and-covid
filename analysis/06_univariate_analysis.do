********************************************************************************
*
*	Do-file:		06_univariate_analysis.do
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
*	Comments: 		I had to create a folder called models within the output folder.
********************************************************************************
*
*	Purpose:		Fit age/sex adjusted Cox models, stratified by STP and 
*with hh size as random effect
*  
********************************************************************************

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
log using "./output/an_univariable_cox_models_`outcome'_`firstvar'TO`lastvar'", text replace

* Open dataset and fit specified model(s)
use "$tempdir\cr_create_analysis_dataset_STSET_`outcome'.dta", clear


foreach var of any `varlist' {

	*Special cases
	if "`var'"=="agesplsex" local model "age1 age2 age3 i.male"
	else if "`var'"=="agegroupsex" local model "ib3.agegroup i.male"
	else if "`var'"=="bmicat" local model "age1 age2 age3 i.male ib2.bmicat"
	*General form of model
	else local model "age1 age2 age3 i.male i.`var'"

	*Fit and save model
	cap erase ./output/an_univariable_cox_models_`outcome'_AGESEX_`var'.ster
	capture stcox `model' , strata(stp) vce(cluster household_size)
	if _rc==0 {
		estimates
		estimates save ./output/an_univariable_cox_models_`outcome'_AGESEX_`var'.ster, replace
		}
	else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"

}


* Close log file
log close
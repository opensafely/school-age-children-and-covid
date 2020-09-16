*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing HRs for interaction analyses.  Also output forest 
*plot of results as SVG file. 
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: HFORBES, based on file from Krishnan Bhaskaran
*
*Date drafted: 30th June 2020
*************************************************************************

local outcome `1' 


***********************************************************************************************************************
*Generic code to ouput the HRs across outcomes for all levels of a particular variables, in the right shape for table
cap prog drop outputHRsforvar
prog define outputHRsforvar
syntax, variable(string) min(real) max(real)
file write tablecontents_int_weeks ("age") _tab ("exposure") _tab ("exposure level") _tab ("outcome") _tab ("week") _tab ("HR") _n
foreach outcome of any  non_covid_death covid_tpp_prob covidadmission covid_icu covid_death     {
forvalues x=0/1 {
forvalues i=`min'/`max'{
forvalues week=0/7 {

local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_int_weeks ("`x'") _tab ("`variable'") _tab ("`i'") _tab ("`outcome'") _tab ("`week'") _tab
	
	foreach modeltype of any fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY

		if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_interaction_cox_models_`outcome'_week`week'_ageband_`x'
				if _rc!=0 local noestimatesflag 1
				}
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0{
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
			}
			else file write tablecontents_int_weeks %4.2f ("DID NOT FIT") `endwith' 
			
		*3) Save the estimates for plotting
		if `noestimatesflag'==0{
			if "`modeltype'"=="fulladj" {
				local hr = r(estimate)
				local lb = r(lb)
				local ub = r(ub)
				cap gen `variable'=.
				testparm i.`variable'
				post HRestimates_int_weeks ("`x'") ("`outcome'") ("`variable'") (`i') (`week') (`hr') (`lb') (`ub') (r(p))
				drop `variable'
				}
		}	
		} 
		} /*int_level*/
		} /*full adj*/
		
} /*variable levels*/
} /*agebands*/
end
***********************************************************************************************************************

*MAIN CODE TO PRODUCE TABLE CONTENTS
cap file close tablecontents_int_weeks
file open tablecontents_int_weeks using ./output/an_int_tab_contents_HRtable_WEEKS.txt, t w replace 

tempfile HRestimates_int_weeks
cap postutil clear
postfile HRestimates_int_weeks str10 x str10 outcome str27 variable level week hr lci uci pval using `HRestimates_int_weeks'

*Primary exposure
outputHRsforvar, variable("kids_cat3") min(1) max(2) 
file write tablecontents_int_weeks _n

file close tablecontents_int_weeks

postclose HRestimates_int_weeks

/* 
forvalues x=0/1 {

use `HRestimates_int_weeks', clear

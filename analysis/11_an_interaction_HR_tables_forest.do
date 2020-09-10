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
syntax, variable(string) min(real) max(real) outcome(string)
file write tablecontents_int ("age") _tab ("exposure") _tab ("exposure level") ///
_tab ("outcome") _tab ("int_type") _tab ("int_level") ///
_tab ("HR")  _tab ("lci")  _tab ("uci") _n
forvalues x=0/1 {
forvalues i=`min'/`max'{
foreach int_type in male cat_time shield {

forvalues int_level=0/1 {

local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_int ("`x'") _tab ("`variable'") _tab ("`i'") _tab ("`outcome'") _tab ("`int_type'") _tab ("`int_level'") _tab
	
	foreach modeltype of any fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY

		if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_interaction_cox_models_`outcome'_`variable'_`int_type'_MAINFULLYADJMODEL_agespline_bmicat_noeth_ageband_`x'  
				if _rc!=0 local noestimatesflag 1
				}
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0{
			if `int_level'==0 {
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents_int %4.2f (r(estimate)) _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _tab `endwith'
				else file write tablecontents_int %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==1 {
			cap lincom `i'.`variable'+ 1.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int %4.2f (r(estimate)) _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _tab `endwith'
				else file write tablecontents_int %4.2f ("ERR IN MODEL") `endwith'
				}
			}
			else file write tablecontents_int %4.2f ("DID NOT FIT") `endwith' 
			
		*3) Save the estimates for plotting
		if `noestimatesflag'==0{
			if "`modeltype'"=="fulladj" {
				local hr = r(estimate)
				local lb = r(lb)
				local ub = r(ub)
				cap gen `variable'=.
				testparm i.`variable'
				post HRestimates_int ("`x'") ("`outcome'") ("`variable'") ("`int_type'") (`i') (`int_level') (`hr') (`lb') (`ub') (r(p))
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
cap file close tablecontents_int
file open tablecontents_int using ./output/11_an_int_tab_contents_HRtable_`outcome'.txt, t w replace 

tempfile HRestimates_int
cap postutil clear
postfile HRestimates_int str10 x str10 outcome str27 variable str27 int_type level int_level hr lci uci pval using `HRestimates_int'

*Primary exposure
outputHRsforvar, variable("kids_cat3") min(1) max(2) outcome(`outcome') 
file write tablecontents_int _n

file close tablecontents_int

postclose HRestimates_int

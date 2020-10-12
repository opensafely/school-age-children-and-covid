*************************************************************************
*Exposure children and COVID risk
  
*03b_an_descriptive_table_1

*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell "Table 1" (main cohort descriptives by exposure status)
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: HFORBES, based on Krishnan Bhaskaran
*
*Date drafted: 30th June 2020
*************************************************************************



* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"

*******************************************************************************
*Generic code to output one row of table
cap prog drop generaterow
log using $logdir/03b_an_descriptive_table_1, replace t

program define generaterow
syntax, variable(varname) condition(string) outcome(string)
	
	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontent ("`variable'") _tab ("`condition'") _tab
	
	cou
	local overalldenom=r(N)
	
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	cou if kids_cat3==0 
	local coldenom = r(N)
	cou if kids_cat3==0 & `variable' `condition'
	local pct = 100*(r(N)/`coldenom')
	file write tablecontent (r(N)) (" (") %4.2f  (`pct') (")") _tab
	
	cou if kids_cat3==1 
	local coldenom = r(N)
	cou if kids_cat3==1 & `variable' `condition'
	local pct = 100*(r(N)/`coldenom')
	file write tablecontent (r(N)) (" (") %4.2f  (`pct') (")") _tab
	
	cou if kids_cat3==2 
	local coldenom = r(N)
	cou if kids_cat3==2 & `variable' `condition'
	local pct = 100*(r(N)/`coldenom')
	file write tablecontent (r(N)) (" (") %4.2f  (`pct') (")") _n
	
end

*******************************************************************************
*Generic code to output one section (varible) within table (calls above)
cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) start(real) end(real) [missing] outcome(string)

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') condition("==`varlevel'") outcome(kids_cat3)
	}
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.") outcome(kids_cat3)

end

*******************************************************************************

*Set up output file

forvalues x=0/1 {

cap file close tablecontent
file open tablecontent using ./output/03b_an_descriptive_table_1_kids_cat3_ageband`x'.txt, write text replace

use $tempdir/analysis_dataset_ageband_`x', clear

gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) outcome(kids_cat3)
file write tablecontent _n 

tabulatevariable, variable(agegroup) start(1) end(7) outcome(kids_cat3) 
file write tablecontent _n 

tabulatevariable, variable(male) start(0) end(1) outcome(kids_cat3)
file write tablecontent _n 

tabulatevariable, variable(bmicat) start(1) end(6) missing outcome(kids_cat3)
file write tablecontent _n 

tabulatevariable, variable(smoke) start(1) end(3) missing outcome(kids_cat3) 
file write tablecontent _n 

tabulatevariable, variable(ethnicity) start(1) end(5) missing outcome(kids_cat3)
file write tablecontent _n 

tabulatevariable, variable(imd) start(1) end(5) outcome(kids_cat3)
file write tablecontent _n 

tabulatevariable, variable(tot_adults_hh) start(1) end(3) outcome(kids_cat3)
file write tablecontent _n 

tabulatevariable, variable(bpcat) start(1) end(4) missing outcome(kids_cat3)
tabulatevariable, variable(htdiag_or_highbp) start(1) end(1) outcome(kids_cat3)			
file write tablecontent _n  

**COMORBIDITIES
*RESPIRATORY
tabulatevariable, variable(chronic_respiratory_disease) start(1) end(1) outcome(kids_cat3)
*ASTHMA
tabulatevariable, variable(asthma) start(1) end(1) outcome(kids_cat3) /*ever asthma*/
*CARDIAC
tabulatevariable, variable(chronic_cardiac_disease) start(1) end(1) outcome(kids_cat3)
file write tablecontent _n
*DIABETES
tabulatevariable, variable(diabcat) start(1) end(6) outcome(kids_cat3) 
file write tablecontent _n
*CANCER EX HAEM
tabulatevariable, variable(cancer_haem_cat) start(2) end(4) outcome(kids_cat3) /*<1, 1-4.9, 5+ years ago*/
file write tablecontent _n
*CANCER HAEM
tabulatevariable, variable(cancer_exhaem_cat) start(2) end(4) outcome(kids_cat3) /*<1, 1-4.9, 5+ years ago*/
file write tablecontent _n
*REDUCED KIDNEY FUNCTION
tabulatevariable, variable(reduced_kidney_function_cat) start(2) end(3) outcome(kids_cat3)
*ESRD
tabulatevariable, variable(esrd) start(1) end(1) outcome(kids_cat3)
*LIVER
tabulatevariable, variable(chronic_liver_disease) start(1) end(1) outcome(kids_cat3)
*STROKE/DEMENTIA
tabulatevariable, variable(stroke_dementia) start(1) end(1) outcome(kids_cat3)
*OTHER NEURO
tabulatevariable, variable(other_neuro) start(1) end(1) outcome(kids_cat3)
*OTHER ORGAN TRANSPLANT
tabulatevariable, variable(other_transplant) start(1) end(1) outcome(kids_cat3)
*SPLEEN
tabulatevariable, variable(asplenia) start(1) end(1) outcome(kids_cat3)
*RA_SLE_PSORIASIS
tabulatevariable, variable(ra_sle_psoriasis) start(1) end(1) outcome(kids_cat3)
*OTHER IMMUNOSUPPRESSION
tabulatevariable, variable(other_immuno) start(1) end(1) outcome(kids_cat3)
*SHEILDING
tabulatevariable, variable(shield) start(1) end(1) outcome(kids_cat3)
*anycomorbidity
tabulatevariable, variable(anycomorb) start(1) end(1) outcome(kids_cat3)

file close tablecontent

}

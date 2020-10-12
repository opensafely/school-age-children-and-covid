*Exposure children and COVID risk
  
*04_an_descriptive_table_1
*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell "Table 2" (main cohort descriptives by outcome status). 
*
*Requires: final analysis dataset (cr_analysis_dataset.dta)
*
*Coding: HFORBES, based on Krishnan Bhaskaran
*
*Date drafted: 30th June 2020
*************************************************************************

local outcome `1' 

*******************************************************************************
*Generic code to output one row of table
cap prog drop generaterow
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

	cou if `outcome'==1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent (r(N)) (" (") %4.2f  (`pct') (")") _n

	
end

*******************************************************************************
*Generic code to output one section (varible) within table (calls above)
cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) start(real) end(real) [missing] outcome(string)

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') condition("==`varlevel'") outcome(`outcome')
	}
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.") outcome(`outcome')

end

*******************************************************************************


forvalues x=0/1 {

*Set up output file
cap file close tablecontent
file open tablecontent using ./output/04b_an_descriptive_table_2_`outcome'.txt, write text replace


use $tempdir/analysis_dataset_worms_ageband_`x', clear


gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) outcome(`outcome')
file write tablecontent _n 

tabulatevariable, variable(agegroup) start(1) end(7) outcome(`outcome') 
file write tablecontent _n 

tabulatevariable, variable(male) start(0) end(1) outcome(`outcome')
file write tablecontent _n 

tabulatevariable, variable(bmicat) start(1) end(6) missing outcome(`outcome')
file write tablecontent _n 

tabulatevariable, variable(smoke) start(1) end(3) missing outcome(`outcome') 
file write tablecontent _n 

tabulatevariable, variable(ethnicity) start(1) end(5) missing outcome(`outcome')
file write tablecontent _n 

tabulatevariable, variable(imd) start(1) end(5) outcome(`outcome')
file write tablecontent _n 

tabulatevariable, variable(tot_adults_hh) start(1) end(3) outcome(`outcome')
file write tablecontent _n 

tabulatevariable, variable(bpcat) start(1) end(4) missing outcome(`outcome')
tabulatevariable, variable(htdiag_or_highbp) start(1) end(1) outcome(`outcome')			
file write tablecontent _n  

**COMORBIDITIES
*RESPIRATORY
tabulatevariable, variable(chronic_respiratory_disease) start(1) end(1) outcome(`outcome')
file write tablecontent _n  
*ASTHMA
tabulatevariable, variable(asthma) start(1) end(2) outcome(`outcome') /*ever asthma*/
*CARDIAC
tabulatevariable, variable(chronic_cardiac_disease) start(1) end(1) outcome(`outcome')
*DIABETES
tabulatevariable, variable(diabcat) start(1) end(6) outcome(`outcome') 
file write tablecontent _n
*CANCER EX HAEM
tabulatevariable, variable(cancer_haem_cat) start(2) end(4) outcome(`outcome') /*<1, 1-4.9, 5+ years ago*/
file write tablecontent _n
*CANCER HAEM
tabulatevariable, variable(cancer_exhaem_cat) start(2) end(4) outcome(`outcome') /*<1, 1-4.9, 5+ years ago*/
file write tablecontent _n
*REDUCED KIDNEY FUNCTION
tabulatevariable, variable(reduced_kidney_function_cat) start(2) end(3) outcome(`outcome')
*ESRD
tabulatevariable, variable(esrd) start(1) end(1) outcome(`outcome')
*LIVER
tabulatevariable, variable(chronic_liver_disease) start(1) end(1) outcome(`outcome')
*STROKE/DEMENTIA
tabulatevariable, variable(stroke_dementia) start(1) end(1) outcome(`outcome')
*OTHER NEURO
tabulatevariable, variable(other_neuro) start(1) end(1) outcome(`outcome')
*ORGAN TRANSPLANT
tabulatevariable, variable(other_transplant) start(1) end(1) outcome(`outcome')
*SPLEEN
tabulatevariable, variable(asplenia) start(1) end(1) outcome(`outcome')
*RA_SLE_PSORIASIS
tabulatevariable, variable(ra_sle_psoriasis) start(1) end(1) outcome(`outcome')
*OTHER IMMUNOSUPPRESSION
tabulatevariable, variable(other_immuno) start(1) end(1) outcome(`outcome')

*SHEILD
tabulatevariable, variable(shield) start(1) end(1) outcome(`outcome')

file close tablecontent


}

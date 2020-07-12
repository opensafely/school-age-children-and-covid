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
forvalues i=`min'/`max'{
foreach int_type in age66 male cat_time shield {

forvalues int_level=0/1 {

local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_int ("`variable'") _tab ("`i'") _tab _tab ("`int_level'")
	
	foreach modeltype of any fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY

		if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_interaction_cox_models_`outcome'_`variable'_`int_type'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
				if _rc!=0 local noestimatesflag 1
				}
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0{
			if `int_level'==0 {
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents_int %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==1 {
			cap lincom `i'.`variable'+ 1.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
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
				post HRestimates_int ("`outcome'") ("`variable'") ("`int_type'") (`i') (`int_level') (`hr') (`lb') (`ub') (r(p))
				drop `variable'
				}
		}	
		} 
		} /*int_level*/
		} /*full adj*/
		
} /*variable levels*/

end
***********************************************************************************************************************
*Generic code to write a full row of "ref category" to the output file
cap prog drop refline
prog define refline
file write tablecontents_int _tab _tab ("1.00 (ref)") _tab ("1.00 (ref)")  _n
*post HRestimates_int ("`outcome'") ("`variable'") (`refcat') (1) (1) (1) (.)
end
***********************************************************************************************************************

*MAIN CODE TO PRODUCE TABLE CONTENTS

cap file close tablecontents_int
file open tablecontents_int using ./output/an_int_tab_contents_HRtable_`outcome'.txt, t w replace 

tempfile HRestimates_int
cap postutil clear
postfile HRestimates_int str10 outcome str27 variable str27 int_type level int_level hr lci uci pval using `HRestimates_int'

*Primary exposure
refline
outputHRsforvar, variable("kids_cat3") min(1) max(2) outcome(`outcome') 
file write tablecontents_int _n

file close tablecontents_int

postclose HRestimates_int

use `HRestimates_int', clear
drop if variable=="gp_number_kids"

gen varorder = 1 
local i=2
foreach var of any 		kids_cat3  ///
		 {
replace varorder = `i' if variable=="`var'"
local i=`i'+1
}
sort varorder level
drop varorder

gen obsorder=_n
expand 2 if variable!=variable[_n-1], gen(expanded)
for var hr lci uci: replace X = 1 if expanded==1

sort obsorder
drop obsorder
replace level = 0 if expanded == 1
replace level = 1 if expanded == 1 & (variable=="kids_cat3")

replace level = 3 if expanded == 1 & variable=="gp_number_kids"

gen varorder = 1 if variable!=variable[_n-1]
replace varorder = sum(varorder)
sort varorder level int_type


drop expanded
expand 2 if variable!=variable[_n-1], gen(expanded)
replace level = -1 if expanded==1
drop expanded

expand 2 if level == -1, gen(expanded)
replace level = -99 if expanded==1
drop expanded

expand 2 if level == 1 & int_type=="age66" & int_level==0, gen(expanded)
replace level = 1.5 if expanded==1
drop expanded
drop if level==1.5 & int_type=="age66" & hr!=1

for var hr lci uci pval : replace X=. if level<0


sort varorder  level int_type int_level
list in 1/10

gen varx = 0.07
gen levelx = 0.073
gen intx=0.08
gen lowerlimit = 0.15

gen Name = variable if (level==-99)
replace Name = "Presence of children or young people in household" if Name=="kids_cat3"


gen obsno=_n
*Levels
gen leveldesc = ""
replace leveldesc = "Children under 12 years" if variable=="kids_cat3" & level==-1
replace leveldesc = "Children/young people aged 11-<18 years" if variable=="kids_cat3" & level==1.5

*Inte labels
gen intNAME=""
replace intNAME="Age under 66 years" if int_type=="age66" & int_level==0
replace intNAME="Age 66 years and above" if int_type=="age66" & int_level==1
replace intNAME="Female" if int_type=="male" & int_level==0
replace intNAME="Male" if int_type=="male" & int_level==1
replace intNAME="Time before 3rd April 2020" if int_type=="cat_time" & int_level==0
replace intNAME="Time on/after 3rd April 2020" if int_type=="cat_time" & int_level==1
replace intNAME="Unlikely to be shielding" if int_type=="shield" & int_level==0
replace intNAME="Probable shielding" if int_type=="shield" & int_level==1
replace intNAME="" if Name!=""
replace intNAME="" if leveldesc!=""


drop if hr==1 & lci==1 &leveldesc==""

foreach var in hr lci uci {
replace  `var'=. if leveldesc=="Children/young people aged 11-<18 years"
}


gen obsorder=_n
gsort -obsorder
gen graphorder = _n
sort obsorder

gen displayhrci = "<<< HR = " + string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")" if lci<0.15

scatter graphorder hr if lci>=.15, mcol(black)	msize(small)		///										///
	|| rcap lci uci graphorder if lci>=.15, hor mcol(black)	lcol(black)			///
	|| scatter graphorder lowerlimit, m(i) mlab(displayhrci) mlabcol(black) mlabsize(tiny) ///
	|| scatter graphorder varx , m(i) mlab(Name) mlabsize(tiny) mlabcol(black) 	///
	|| scatter graphorder levelx, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8) 	///
	|| scatter graphorder intx, m(i) mlab(intNAME) mlabsize(tiny) mlabcol(gs8) 	///
		xline(1,lp(dash)) 															///
		xscale(log) xlab(0.25 0.5 1 2 5 10) xtitle("Hazard Ratio & 95% CI") ylab(none) ytitle("")						/// 
		legend(off)  ysize(8) 

graph export ./output/an_tablecontent_HRtable_HRforest_int_`outcome'.svg, as(svg) replace

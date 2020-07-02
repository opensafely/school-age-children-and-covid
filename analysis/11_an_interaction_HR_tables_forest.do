*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing minimally and fully-adjusted HRs for risk factors
* of interest, across 2 outcomes 
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
forvalues age=0/1{

local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_int ("`variable'") _tab ("`i'") _tab _tab ("`age'")
	
	foreach modeltype of any fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY

		if "`modeltype'"=="fulladj" {
				cap estimates use ./output/an_interaction_cox_models_`outcome'_`variable'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
				if _rc!=0 local noestimatesflag 1
				}
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0{
			if `age'==0 {
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents_int %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int %4.2f ("ERR IN MODEL") `endwith'
				}
			if `age'==1 {
			cap lincom `i'.`variable'+ 1.age66#`i'.`variable', eform
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
				post HRestimates_int ("`outcome'") ("`variable'") (`i') (`age') (`hr') (`lb') (`ub') (r(p))
				drop `variable'
				}
		}	
		} /*age*/
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
postfile HRestimates_int str10 outcome str27 variable level age hr lci uci pval using `HRestimates_int'

*Primary exposure
refline
outputHRsforvar, variable("kids_cat3") min(1) max(2) outcome(`outcome') 
file write tablecontents_int _n

*Kids under 18
refline
outputHRsforvar, variable("kids_cat2_0_18yrs") min(1) max(1) outcome(`outcome') 
file write tablecontents_int _n

*kids 1-11 years
refline
outputHRsforvar, variable("kids_cat2_1_12yrs") min(1) max(1) outcome(`outcome') 
file write tablecontents_int _n

*Number kids
refline
outputHRsforvar, variable("gp_number_kids") min(1) max(4) outcome(`outcome')
file write tablecontents_int _n 


file close tablecontents_int

postclose HRestimates_int

use `HRestimates_int', clear 


/*TBC.....

gen varorder = 1 
local i=2
foreach var of any 		kids_cat3  ///
		kids_cat2_0_18yrs  ///
		kids_cat2_1_12yrs  ///
		gp_number_kids {
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
sort varorder level


drop expanded
expand 2 if variable!=variable[_n-1], gen(expanded)
replace level = -1 if expanded==1
drop expanded
*expand 3 if variable=="htdiag_or_highbp" & level==-1, gen(expanded)
*replace level = -99 if variable=="htdiag_or_highbp" & expanded==1
expand 2 if level == -1, gen(expanded)
replace level = -99 if expanded==1

for var hr lci uci pval : replace X=. if level<0


sort varorder level age

gen varx = 0.07
gen levelx = 0.071
gen lowerlimit = 0.15

*Names
gen Name = variable if (level==-1&!(level[_n+1]==0&variable!="kids_cat2_1_12yrs"))|(level==1&level[_n-1]==0&variable!="kids_cat2_1_12yrs")
replace Name = variable if (level==0&!(level[_n+1]==0&variable!="kids_cat2_0_18yrs"))|(level==1&level[_n-1]==0&variable!="kids_cat2_0_18yrs")
*replace Name = subinstr(Name, "_", " ", 10)
*replace Name = upper(substr(Name,1,1)) + substr(Name,2,.)
replace Name = "Presence of children or young people in household" if Name=="kids_cat3"
replace Name = "Presence of under 18s in household" if Name=="kids_cat2_0_18yrs"
replace Name = "Presence of children aged 1-<12 years in household" if Name=="kids_cat2_1_12yrs"
replace Name = "Number children under 12 years in household" if Name=="gp_number_kids"


*Levels
gen leveldesc = ""
replace leveldesc = "Children under 12 years" if variable=="kids_cat3" & level==1
replace leveldesc = "Children/young people aged 11-<18 years" if variable=="kids_cat3" & level==2

*replace leveldesc = "Children under 18 years" if variable=="kids_cat2_0_18yrs" & level==1

*replace leveldesc = "Children age 1-<12 years" if variable=="kids_cat2_1_12yrs" & level==1

replace leveldesc = "1" if variable=="gp_number_kids" & level==1
replace leveldesc = "2" if variable=="gp_number_kids" & level==2
replace leveldesc = "3" if variable=="gp_number_kids" & level==3
replace leveldesc = "4 or more" if variable=="gp_number_kids" & level==4

*replace leveldesc = "Absent" if level==0
*replace leveldesc = "Present" if level==1 & leveldesc==""
drop if level==0 & variable!="male"


gen obsorder=_n
gsort -obsorder
gen graphorder = _n
sort obsorder

*merge 1:1 variable level using c:\statatemp\tptemp, update replace

replace Name="" if level==-1 & variable=="kids_cat2_1_12yrs"

gen displayhrci = "<<< HR = " + string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")" if lci<0.15

scatter graphorder hr if lci>=.15, mcol(black)	msize(small)		///										///
	|| rcap lci uci graphorder if lci>=.15, hor mcol(black)	lcol(black)			///
	|| scatter graphorder lowerlimit, m(i) mlab(displayhrci) mlabcol(black) mlabsize(tiny) ///
	|| scatter graphorder varx , m(i) mlab(Name) mlabsize(tiny) mlabcol(black) 	///
	|| scatter graphorder levelx, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8) 	///
		xline(1,lp(dash)) 															///
		xscale(log) xlab(0.25 0.5 1 2 5 10) xtitle("Hazard Ratio & 95% CI") ylab(none) ytitle("")						/// 
		legend(off)  ysize(4) 

graph export ./output/an_tablecontent_HRtable_HRforest_`outcome'.svg, as(svg) replace

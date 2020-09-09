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
foreach int_type in weeks {

forvalues int_level=0/7 {

local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents_int_weeks ("`x'") _tab ("`variable'") _tab ("`i'") _tab ("`outcome'") _tab ("`int_level'") _tab
	
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
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==1 {
			cap lincom `i'.`variable'+ 1.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==2 {
			cap lincom `i'.`variable'+ 2.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==3 {
			cap lincom `i'.`variable'+ 3.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==4 {
			cap lincom `i'.`variable'+ 4.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==5 {
			cap lincom `i'.`variable'+ 5.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==6 {
			cap lincom `i'.`variable'+ 6.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
			if `int_level'==7 {
			cap lincom `i'.`variable'+ 7.`int_type'#`i'.`variable', eform
			if _rc==0 file write tablecontents_int_weeks %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents_int_weeks %4.2f ("ERR IN MODEL") `endwith'
				}
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
				post HRestimates_int_weeks ("`x'") ("`outcome'") ("`variable'") ("`int_type'") (`i') (`int_level') (`hr') (`lb') (`ub') (r(p))
				drop `variable'
				}
		}	
		} 
		} /*int_level*/
		} /*full adj*/
		
} /*variable levels*/
} /*agebands*/
} /*outcomes*/
end
***********************************************************************************************************************

*MAIN CODE TO PRODUCE TABLE CONTENTS
cap file close tablecontents_int_weeks
file open tablecontents_int_weeks using ./output/an_int_tab_contents_HRtable_WEEKS.txt, t w replace 

tempfile HRestimates_int_weeks
cap postutil clear
postfile HRestimates_int_weeks str10 x str10 outcome str27 variable str27 int_type level int_level hr lci uci pval using `HRestimates_int_weeks'

*Primary exposure
outputHRsforvar, variable("kids_cat3") min(1) max(2) 
file write tablecontents_int_weeks _n

file close tablecontents_int_weeks

postclose HRestimates_int_weeks

/* 
forvalues x=0/1 {

use `HRestimates_int_weeks', clear
keep if x=="`x'"
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

gen varx = 0.07
gen levelx = 0.073
gen intx=0.08
gen lowerlimit = 0.15

gen Name = variable if (level==-99)
replace Name = "Presence of children or young people in household" if Name=="kids_cat3"
gen hrtitle="Hazard Ratio (95% CI)" if (level==-99)

gen obsno=_n
*Levels
gen leveldesc = ""

replace leveldesc = "Children under 12 years" if variable=="kids_cat3" & level==-1
replace obsno=9.5 if obsno==6
replace leveldesc = "Children/young people aged 11-<18 years" if obsno==9.5
sort obsno

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
gen disx=4

gen displayhrci = string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")"
replace displayhrci="" if hr==.
list display 

list obsorder obsno Name level leveldesc int_type hr   lci uci 

gen bf_hrtitle = "{bf:" + hrtitle + "}" 
gen bf_Name = "{bf:" + Name + "}" 
gen bf_leveldesc = "{bf:" + leveldesc + "}" 


scatter graphorder hr if lci>=.15, mcol(black)	msize(small)		///										///
	|| rcap lci uci graphorder if lci>=.15, hor mcol(black)	lcol(black)			///
	|| scatter graphorder varx , m(i) mlab(bf_Name) mlabsize(vsmall) mlabcol(black) 	///
	|| scatter graphorder levelx, m(i) mlab(bf_leveldesc) mlabsize(vsmall) mlabcol(black) 	///
	|| scatter graphorder intx, m(i) mlab(intNAME) mlabsize(vsmall) mlabcol(black) 	///
	|| scatter graphorder disx, m(i) mlab(displayhrci) mlabsize(vsmall) mlabcol(black) ///
	|| scatter graphorder disx, m(i) mlab(bf_hrtitle) mlabsize(vsmall) mlabcol(black) ///
		xline(1,lp(dash)) 															///
		xscale(log range(0.1 10)) xlab(0.5 1 2 , labsize(small)) ///
		xtitle("           ", size(vsmall) ) ///
		ylab(none) ytitle("")  yscale( lcolor(white))					/// 
		graphregion(color(white))  legend(off)  ysize(4) ///
		text(-0.5 0.2 "Lower risk in those living with children", place(e) size(vsmall)) ///
		text(-0.5 1.5 "Higher risk in those living with children", place(e) size(vsmall))

graph export ./output/an_tablecontent_HRtable_HRforest_int_`outcome'_ageband_`x'.svg, as(svg) replace
}

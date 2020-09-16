
*******************************************************************************
*>> HOUSEKEEPING
*******************************************************************************/
*clear

version 15
clear all
capture log close

* create a filename global that can be used throughout the file
global filename "forest_plot"

global globalpath "C:\Users\ENCDHFOR\Documents\GitHub\school-age-children-and-covid\analysis\output"
global shared_folder "C:\Users\ENCDHFOR\Dropbox\EHR-Working\Harriet\Covid19\Schools_study\graphs"
ssc install metan
*ssc install admetan


/*******************************************************************************
#1. graph for each outcome, and age group
*******************************************************************************/
*cat_time shield
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
foreach age in 0 1  {

import delimited $globalpath/11_an_int_tab_contents_HRtable_`outcome'.txt, clear
keep if age==`age'

list

gen log_est = log(hr)
gen log_lci = log(lci)
gen log_uci = log(uci)
lab define  age 0 "Age <=65 years" 1 "Age>65 years"
lab values age age

lab define exposurelevel 1 "Children under 12 years" 2 "Children/young people aged 11-<18 years" 
lab val exposurelevel exposurelevel

replace int_type= "Time period" if int_type=="cat_time"
replace int_type= "Sex" if int_type=="male"
replace int_type= "Shielding" if int_type=="shield"

gen int_level_new="Female" if int_type=="Sex" & int_level==0
replace int_level_new="Male" if int_type=="Sex" & int_level==1
replace int_level_new="Time before 3rd April 2020" if int_type=="Time period" & int_level==0
replace int_level_new="Time after 3rd April 2020" if int_type=="Time period" & int_level==1
replace int_level_new="Not shielding" if int_type=="Shielding" & int_level==0
replace int_level_new="Probable shielding" if int_type=="Shielding" & int_level==1

lab var int_level_new "Level"
lab var int_type "Interaction"

if "`outcome'"=="non_covid_death" {
local title="Non-covid-19 death" 
}
if "`outcome'"=="covid_tpp_prob" {
local title="COVID-19 probable clinical infection"
}
if "`outcome'"=="covid_icu" {
local title="COVID-19 ICU admission" 
}
if "`outcome'"=="covid_death" {
local title="COVID-19 death" 
}
if "`outcome'"=="covidadmission" {
local title="COVID-19 hospital admission" 
}
   
if "`age'"=="1" {
local agetitle="Age>65 years" 
}
if "`age'"=="0" {
local agetitle="Age <=65 years"
}
**********************************************************************
***Plot hazard ratios
**********************************************************************
metan log_est log_lci log_uci, eform random ///
	lcols(int_type int_level_new ) olineopt(lpattern(dash) lwidth(vthin)) ///
	diamopt(lcolor(blue)) ///
	nowarning nobox effect(Hazard Ratio) xlab (.8,1,1.25,1.5)  ///
	graphregion(color(white)) nooverall nowt nohet texts(100) astext(55) ///
	nosubgroup by(exposurelevel) title("`title': `agetitle'", size(small))
	graph export "$shared_folder\interactions_`outcome'_`age'.png", as(png) replace 

	} /*ages*/
	
} /*outcomes*/	


*******************************************************************************
*1. graph for interaction type
*******************************************************************************/

*Save text files as stata files
foreach outcome of any non_covid_death covid_tpp_prob covidadmission covid_icu covid_death {
import delimited $globalpath/11_an_int_tab_contents_HRtable_`outcome'.txt, clear
save $shared_folder/`outcome', replace
}

*combine results from all outcomes in one file
use $shared_folder/non_covid_death, clear
foreach outcome of any covid_tpp_prob covidadmission covid_icu covid_death {
append using $shared_folder/`outcome'
}
save $shared_folder/interactions_all, replace

erase $shared_folder/non_covid_death.dta 
erase $shared_folder/covid_tpp_prob.dta 
erase  $shared_folder/covidadmission.dta 
erase  $shared_folder/covid_icu.dta 
erase  $shared_folder/covid_death.dta 



foreach int_type in male cat_time shield {

use $shared_folder/interactions_all, clear
keep if int_type=="`int_type'"

list

gen log_est = log(hr)
gen log_lci = log(lci)
gen log_uci = log(uci)
lab define  age 0 "Age <=65 years" 1 "Age>65 years"
lab values age age

lab define exposurelevel 1 "Children under 12 years" 2 "Children/young people aged 11-<18 years" 
lab val exposurelevel exposurelevel

replace int_type= "Time period" if int_type=="cat_time"
replace int_type= "Sex" if int_type=="male"
replace int_type= "Shielding" if int_type=="shield"

gen int_level_new="Female" if int_type=="Sex" & int_level==0
replace int_level_new="Male" if int_type=="Sex" & int_level==1
replace int_level_new="Time before 3rd April 2020" if int_type=="Time period" & int_level==0
replace int_level_new="Time after 3rd April 2020" if int_type=="Time period" & int_level==1
replace int_level_new="Not shielding" if int_type=="Shielding" & int_level==0
replace int_level_new="Probable shielding" if int_type=="Shielding" & int_level==1
	
lab var int_level_new "Interaction factor"
lab var int_type "Interaction"

encode outcome, gen(outcome_new)  
recode outcome_new 3=1 2=3 4=2 1=4
lab drop outcome_new
lab define outcome_new 1 "COVID-19 probable clinical infection"  ///
2 "COVID-19 hospital admission" ///
3 "COVID-19 ICU admission" ///
4 "COVID-19 death" ///
5 "Non-covid-19 death"  
lab val outcome_new outcome_new
tab outcome outcome_new
lab var outcome_new "Outcome"
lab var exposurelevel "Exposure"

sort outcome_new int_level_new exposurelevel
**********************************************************************
***Pool the odds ratios for the studies
**********************************************************************
metan log_est log_lci log_uci, eform random ///
	lcols(outcome_new exposurelevel int_level_new ) olineopt(lpattern(dash) lwidth(vthin)) ///
	diamopt(lcolor(blue)) ///
	nowarning nobox effect(Hazard Ratio) xlab (.8,1,1.25,1.5)  ///
	graphregion(color(white)) nooverall nowt nohet texts(100) astext(55) ///
	nosubgroup by(age) 
	graph export $shared_folder/interactions_`int_type'.png, as(png) replace 

	} 
	

*******************************************************************************
*Weeks
*******************************************************************************

foreach age in 0 1  {
import delimited $globalpath/an_int_tab_contents_HRtable_WEEKS.txt, clear
drop if outcome=="non_covid_death"
keep if age==`age'

list
gen hronly=substr(hr, 1,4)
list hr*
gen lcionly=substr(hr, 7,4)
list hr* lci
gen ucionly=substr(hr, 12,4)
list hr* uci

foreach var in hronly lcionly ucionly {
destring `var', replace
}

gen log_est = log(hronly)
gen log_lci = log(lcionly)
gen log_uci = log(ucionly)
lab define  age 0 "Age <=65 years" 1 "Age>65 years"
lab values age age

lab define exposurelevel 1 "Children under 12 years" 2 "Children/young people aged 11-<18 years" 
lab val exposurelevel exposurelevel


encode outcome, gen(outcome_new) 
recode outcome_new 3=1 2=3 4=2 1=4
lab drop outcome_new
lab define outcome_new 1 "COVID-19 probable clinical infection"  ///
2 "COVID-19 hospital admission" ///
3 "COVID-19 ICU admission" ///
4 "COVID-19 death" ///
5 "Non-covid-19 death"  
lab val outcome_new outcome_new
tab outcome outcome_new
lab var outcome_new "Outcome"

lab var exposurelevel "Exposure"
lab var week "Weeks after 3rd April 2020"

lab define week 0 "1st February 2020-2nd April 2020" ///
1 "1 week" 2 "2 weeks" 3 "3 weeks" 4 "4 weeks" 5 "5 weeks" 6 "6 weeks"  7 "15th May 2020" 
lab val week week

sort outcome_new exposurelevel week
**********************************************************************
***Pool the odds ratios for the studies
**********************************************************************
metan log_est log_lci log_uci, eform random ///
	lcols(week exposurelevel ) olineopt(lpattern(dash) lwidth(vthin)) ///
	diamopt(lcolor(blue)) ///
	nowarning nobox effect(Hazard Ratio) xlab (.8,1,1.25,1.5)  ///
	graphregion(color(white)) nooverall nowt nohet texts(100) astext(55) ///
	nosubgroup by(outcome_new) 
	graph export $shared_folder/interactions_WEEKS_`age'.png, as(png) replace 

}

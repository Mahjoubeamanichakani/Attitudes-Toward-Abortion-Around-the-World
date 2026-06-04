clear
clear all
clear matrix


********************************************************
*First: Looking at the last wave of World value survey(7)
********************************************************

/* This study uses Wave 7 of the World Values Survey (WVS), a cross-national database with 97,220 respondents (Haerpfer et.al., 2022). The dataset and its codebook is available at this link from the WVS website and is open-access with permission, so no additional ethical approval or permissions are required: https://www.worldvaluessurvey.org/WVSDocumentationWV7.jsp 
(Also you can find them in the shared foulder)
The majority of the surveys were conducted between 2017 and 2020, and a smaller subset was collected post-pandemic in 2021–2023. 
*/

log using "abortion-7&long.log", replace

cd "${datao}"
import delimited "WVS_Cross-National_Wave_7_csv_v6_0.csv", clear



********************************************************
*Summary of selected variables
********************************************************
list incomewb in 1/10
describe q184 i_abortlib q262 q261 q260 incomewb q273 h_urbrural gii q37 q50 q274
summarize q184 i_abortlib q262 q261 q260 incomewb q273 h_urbrural gii q37 q50 q274



********************************************************
* Recode and clean variables
********************************************************
/*
As the first step, I selected and kept relevant variables and recoded them to proper names and formats. A primary outcome of interest is abortion attitudes, measured via question Q184, which asks respondents to rate whether abortion is justified on a ten-point ordinal scale ranging from "never justifiable" (1) to "always justifiable" (10). This variable was used in both its full ordinal form and a recoded version that changed responses into three categories, low, neutral, and high justifiability, for robustness checks.
*/
gen abortion_justif = q184
replace abortion_justif = . if inlist(abortion_justif, -5, -4, -2, -1)


/*
Three key independent variables are considered. The first is the question about the duty of people to society to have children with the use of this question: "it is a duty towards society to have children" (Q37), measured on a five-point Likert scale from strong agreement to strong disagreement. In my opinion, this variable could reflect pro natalist attitudes and could strengthen the explanation of abortion attitudes in relation to demographic anxiety. Second is household financial satisfaction (Q50), rated on a ten-point scale from complete dissatisfaction to complete satisfaction. I chose this variable because I thought it could provide a good representation of how economic instabilities relate to abortion views. The third variable is the Gender Inequality Index (GII), which is a country level, continuous variable between 0 and 1 based on UNDP (2018) definition. To account for sociodemographic variation, the analysis controls for age (Q262), sex (Q260), marital status (Q273), and urban or rural residence (H_URBRURAL). Country-level identifiers are included both as fixed and varying effects to account for unobserved heterogeneity across national contexts. */

gen duty_children = q37
replace duty_children = . if inlist(duty_children, -5, -4, -2, -1)

gen fin_satisfaction = q50
replace fin_satisfaction = . if inlist(fin_satisfaction, -5, -4, -2, -1)

gen GII_clean = gii
replace GII_clean = . if GII_clean <= 0 | GII_clean < -999

gen age = q262
replace age = . if age <= 0

gen sex = q260
replace sex = . if sex <= 0

gen marital_status = q273
replace marital_status = . if marital_status <= 0

gen urban_rural = h_urbrural
replace urban_rural = . if urban_rural <= 0

gen country = incomewb
replace country = . if country <= 0

drop if missing(abortion_justif, age, sex, marital_status, urban_rural, duty_children, fin_satisfaction, country, GII_clean)

list abortion_justif in 1/10
sum abortion_justif
tab abortion_justif, m

*label values
label define sexlbl 1 "Male" 2 "Female"
label values sex sexlbl

label define marlbl 1 "Married" 2 "Living together" 3 "Divorced" 4 "Separated" 5 "Widowed" 6 "Single"
label values marital_status marlbl

label define urblbl 1 "Urban" 2 "Rural"
label values urban_rural urblbl

label define dutylbl 1 "Agree strongly" 2 "Agree" 3 "Neither agree nor disagree" 4 "Disagree" 5 "Disagree strongly"
label values duty_children dutylbl

label define countrylbl 1 "Low income" 2 "Lower-middle income" 3 "Upper-middle income" 4 "High income"
label values country countrylbl


********************************************************
*Descriptive statistics and data visualization
********************************************************

histogram abortion_justif, discrete width(1) start(1) ///
    xtitle("Attitudes toward abortion (1=Never, 5=Neutral, 10=Always Justifiable)") ///
    ylabel(, angle(0)) title("Distribution of Abortion Attitudes")

graph export "First_graph.png", replace

* Cumulative distribution
gen one = 1
gen pr_k = .
gen cum_pr_k = .


tab abortion_justif, gen(freq_)
gen total = _N

forvalues i = 1/10 {
    quietly count if abortion_justif == `i'
    local n = r(N)
    replace pr_k = `n'/total if abortion_justif == `i'
}

gsort abortion_justif
gen cum_p = .
gen logit_cum_p = .
tempvar running_total
gen `running_total' = 0
gen cum_sum = 0


gen cum_freq = .
sort abortion_justif
qui su abortion_justif, meanonly
local n = r(max)

forvalues i = 1/`n' {
    qui count if abortion_justif <= `i'
    local c = r(N)
    replace cum_freq = `c'/total if abortion_justif == `i'
    replace logit_cum_p = log(cum_freq / (1 - cum_freq)) if abortion_justif == `i'
}

twoway line cum_freq abortion_justif, title("Cumulative Proportion of Abortion Justifiability") xtitle("Attitudes (1–10)") ytitle("Cumulative Proportion") yscale(range(0 1)) yline(0.5, lcolor(gray) lpattern(dash))
graph export "Second_graph.png", replace

********************************************************
*Initial Analysis
********************************************************
 ** I am still working on this part
ologit abortion_justif i.duty_children i.fin_satisfaction age i.sex i.marital_status i.urban_rural GII_clean i.country

ologit abortion_justif i.duty_children i.fin_satisfaction age i.sex i.marital_status i.urban_rural GII_clean i.country, or

*Multilevel Ordered Logistic Model
meologit abortion_justif i.duty_children i.fin_satisfaction age i.sex i.marital_status i.urban_rural i.country || GII_clean:, or




***********************************************************
*Second: Looking at the all waves of World value survey(1-7)
**********************************************************

clear
clear all
clear matrix

/*
Haerpfer, C., Inglehart, R., Moreno, A., Welzel, C., Kizilova, K., Diez-Medrano J., M. Lagos, P. Norris, E. Ponarin & B. Puranen et al. (eds.). 2022. World Values Survey Trend File (1981-2022) Cross-National Data-Set. Madrid, Spain  &  Vienna,  Austria:  JD  Systems  Institute  &  WVSA Secretariat. Data File Version 4.0.0, doi:10.14281/18241.27.

*/

cd "${datao}"


import delimited "$Abortion Project\WVS_Time_Series_1981-2022_csv_v5_0.csv"

********************************************************
* Data Cleaning
********************************************************

foreach var in abortion_justif Ideal_Child duty_children{
    replace `var' = . if inlist(`var', -5, -4, -2, -1)
}

* drop if missing(abortion_justif, Ideal_Child, duty_children)

list abortion_justif Year_survey Country_wave_study Country_wave Country_year duty_children Ideal_Child Pronatal in 1/10


label define countrylbl ///
81998 "Albania (1998)" ///
82002 "Albania (2002)" ///
82008 "Albania (2008)" ///
122002 "Algeria (2002)" ///
202005 "Andorra (2005)" ///
311997 "Azerbaijan (1997)" ///
312008 "Azerbaijan (2008)" ///
321984 "Argentina (1984)" ///
321991 "Argentina (1991)" ///
321995 "Argentina (1995)" ///
321999 "Argentina (1999)" ///
322006 "Argentina (2006)" ///
361981 "Australia (1981)" ///
361995 "Australia (1995)" ///
362005 "Australia (2005)" ///
401990 "Austria (1990)" ///
401999 "Austria (1999)" ///
402008 "Austria (2008)" ///
501996 "Bangladesh (1996)" ///
502002 "Bangladesh (2002)" ///
511997 "Armenia (1997)" ///
512008 "Armenia (2008)" ///
561981 "Belgium (1981)" ///
561990 "Belgium (1990)" ///
561999 "Belgium (1999)" ///
562009 "Belgium (2009)" ///
701998 "Bosnia and Herzegovina (1998)" ///
702001 "Bosnia and Herzegovina (2001)" ///
702008 "Bosnia Herzegovina (2008)" ///
761991 "Brazil (1991)" ///
761997 "Brazil (1997)" ///
762006 "Brazil (2006)" ///
1001990 "Bulgaria (1990)" ///
1001997 "Bulgaria (1997)" ///
1001999 "Bulgaria (1999)" ///
1002006 "Bulgaria (2006)" ///
1002008 "Bulgaria (2008)" ///
1121990 "Belarus (1990)" ///
1121996 "Belarus (1996)" ///
1122000 "Belarus (2000)" ///
1122008 "Belarus (2008)" ///
1241982 "Canada (1982)" ///
1241990 "Canada (1990)" ///
1242000 "Canada (2000)" ///
1242006 "Canada (2006)" ///
1521990 "Chile (1990)" ///
1521996 "Chile (1996)" ///
1522000 "Chile (2000)" ///
1522006 "Chile (2006)" ///
1561990 "China (1990)" ///
1561995 "China (1995)" ///
1562001 "China (2001)" ///
1562007 "China (2007)" ///
1581994 "Taiwan (1994)" ///
1582006 "Taiwan (2006)" ///
1701997 "Colombia (1997)" ///
1701998 "Colombia (1998)" ///
1702005 "Colombia (2005)" ///
1911996 "Croatia (1996)" ///
1911999 "Croatia (1999)" ///
1912008 "Croatia (2008)" ///
1962006 "Cyprus (2006)" ///
1962008 "Cyprus (2008)" ///
1972008 "Northern Cyprus (2008)" ///
2031990 "Czech Republic (1990)" ///
2031991 "Czech Republic (1991)" ///
2031998 "Czech Republic (1998)" ///
2031999 "Czech Republic (1999)" ///
2032008 "Czech Republic (2008)" ///
2081981 "Denmark (1981)" ///
2081990 "Denmark (1990)" ///
2081999 "Denmark (1999)" ///
2082008 "Denmark (2008)" ///
2141996 "Dominican Republic (1996)" ///
2331990 "Estonia (1990)" ///
2331996 "Estonia (1996)" ///
2332008 "Estonia (2008)" ///
2461990 "Finland (1990)" ///
2461996 "Finland (1996)" ///
2462000 "Finland (2000)" ///
2501990 "France (1990)" ///
2502006 "France (2006)" ///
2502008 "France (2008)" ///
2681996 "Georgia (1996)" ///
2682008 "Georgia (2008)" ///
2761990 "Germany (1990)" ///
2762006 "Germany (2006)" ///
3002008 "Greece (2008)" ///
3202004 "Guatemala (2004)" ///
3481982 "Hungary (1982)" ///
3481998 "Hungary (1998)" ///
3482008 "Hungary (2008)" ///
3521984 "Iceland (1984)" ///
3521990 "Iceland (1990)" ///
3561990 "India (1990)" ///
3602006 "Indonesia (2006)" ///
3642000 "Iran (2000)" ///
3682004 "Iraq (2004)" ///
3682006 "Iraq (2006)" ///
3721990 "Ireland (1990)" ///
3722008 "Ireland (2008)" ///
3801990 "Italy (1990)" ///
3921990 "Japan (1990)" ///
3922000 "Japan (2000)" ///
4101982 "South Korea (1982)" ///
4101990 "South Korea (1990)" ///
4101996 "South Korea (1996)" ///
4281996 "Latvia (1996)" ///
4282008 "Latvia (2008)" ///
4401997 "Lithuania (1997)" ///
4402008 "Lithuania (2008)" ///
4422008 "Luxembourg (2008)" ///
4702008 "Malta (2008)" ///
4841981 "Mexico (1981)" ///
4841996 "Mexico (1996)" ///
4842000 "Mexico (2000)" ///
4842005 "Mexico (2005)" ///
4981996 "Moldova (1996)" ///
4982008 "Moldova (2008)" ///
4992008 "Montenegro (2008)" ///
5042001 "Morocco (2001)" ///
5281981 "Netherlands (1981)" ///
5282008 "Netherlands (2008)" ///
5542004 "New Zealand (2004)" ///
5662000 "Nigeria (2000)" ///
5781996 "Norway (1996)" ///
5782008 "Norway (2008)" ///
5861997 "Pakistan (1997)" ///
5862001 "Pakistan (2001)" ///
6041996 "Peru (1996)" ///
6042001 "Peru (2001)" ///
6081996 "Philippines (1996)" ///
6082001 "Philippines (2001)" ///
6161989 "Poland (1989)" ///
6161997 "Poland (1997)" ///
6162005 "Poland (2005)" ///
6162008 "Poland (2008)" ///
6202008 "Portugal (2008)" ///
6302001 "Puerto Rico (2001)" ///
6421993 "Romania (1993)" ///
6422005 "Romania (2005)" ///
6422008 "Romania (2008)" ///
6432008 "Russia (2008)" ///
6882008 "Serbia (2008)" ///
7032008 "Slovak Republic (2008)" ///
7042001 "Viet Nam (2001)" ///
7051992 "Slovenia (1992)" ///
7052005 "Slovenia (2005)" ///
7052008 "Slovenia (2008)" ///
7101996 "South Africa (1996)" ///
7102001 "South Africa (2001)" ///
7162001 "Zimbabwe (2001)" ///
7241981 "Spain (1981)" ///
7242000 "Spain (2000)" ///
7242008 "Spain (2008)" ///
7521996 "Sweden (1996)" ///
7522009 "Sweden (2009)" ///
7561989 "Switzerland (1989)" ///
7561996 "Switzerland (1996)" ///
7562008 "Switzerland (2008)" ///
7921996 "Turkey (1996)" ///
7922001 "Turkey (2001)" ///
7922009 "Turkey (2009)" ///
8002001 "Uganda (2001)" ///
8041996 "Ukraine (1996)" ///
8042008 "Ukraine (2008)" ///
8072001 "Macedonia (2001)" ///
8072008 "Macedonia (2008)" ///
8182000 "Egypt (2000)" ///
8182008 "Egypt (2008)" ///
8261981 "UK (1981)" ///
8262005 "UK (2005)" ///
8262009 "UK (2009)" ///
8342001 "Tanzania (2001)" ///
8401995 "United States (1995)" ///
8622000 "Venezuela (2000)" ///
8912001 "Serbia and Montenegro (2001)" ///
9002008 "Germany West (2008)" ///
9012008 "Germany East (2008)" ///
9021995 "Tambov (1995)" ///
9041995 "Basque Country (1995)" ///
9071995 "Galicia (1995)" ///
9092008 "Northern Ireland (2008)" ///
9101995 "Valencia (1995)" ///
9112001 "Serbia (2001)" ///
9122001 "Montenegro (2001)" ///
9132001 "SrpSka - Serbian Republic of Bosnia (2001)" ///
9142001 "Bosnia Federation (2001)" ///
9152008 "Kosovo (2008)" ///
482014 "Bahrain (2014)" ///
81998 "Albania (1998)" ///
82002 "Albania (2002)" ///
82008 "Albania (2008)" ///
122002 "Algeria (2002)" ///
122013 "Algeria (2013)" ///
202005 "Andorra (2005)" ///
311997 "Azerbaijan (1997)" ///
312008 "Azerbaijan (2008)" ///
312011 "Azerbaijan (2011)" ///
321984 "Argentina (1984)" ///
321991 "Argentina (1991)" ///
321995 "Argentina (1995)" ///
321999 "Argentina (1999)" ///
322006 "Argentina (2006)" ///
322013 "Argentina (2013)" ///
361981 "Australia (1981)" ///
361995 "Australia (1995)" ///
362005 "Australia (2005)" ///
362012 "Australia (2012)" ///
401990 "Austria (1990)" ///
401999 "Austria (1999)" ///
402008 "Austria (2008)" ///
501996 "Bangladesh (1996)" ///
502002 "Bangladesh (2002)" ///
511997 "Armenia (1997)" ///
512008 "Armenia (2008)" ///
512011 "Armenia (2011)" ///
561981 "Belgium (1981)" ///
561990 "Belgium (1990)" ///
561999 "Belgium (1999)" ///
562009 "Belgium (2009)" ///
701998 "Bosnia and Herzegovina (1998)" ///
702001 "Bosnia and Herzegovina (2001)" ///
702008 "Bosnia Herzegovina (2008)" ///
761991 "Brazil (1991)" ///
761997 "Brazil (1997)" ///
762006 "Brazil (2006)" ///
1001991 "Bulgaria (1991)" ///
1001997 "Bulgaria (1997)" ///
1001999 "Bulgaria (1999)" ///
1002006 "Bulgaria (2006)" ///
1002008 "Bulgaria (2008)" ///
1002005 "Bulgaria (2005)" ///
1011998 "Srp Ska (1998)" ///
1121990 "Belarus (1990)" ///
1121996 "Belarus (1996)" ///
1122000 "Belarus (2000)" ///
1122008 "Belarus (2008)" ///
1122011 "Belarus (2011)" ///
1241982 "Canada (1982)" ///
1241990 "Canada (1990)" ///
1242000 "Canada (2000)" ///
1242006 "Canada (2006)" ///
1521990 "Chile (1990)" ///
1521996 "Chile (1996)" ///
1522000 "Chile (2000)" ///
1522006 "Chile (2006)" ///
1522011 "Chile (2011)" ///
1561990 "China (1990)" ///
1561995 "China (1995)" ///
1562001 "China (2001)" ///
1562007 "China (2007)" ///
1562012 "China (2012)" ///
1581994 "Taiwan (1994)" ///
1582006 "Taiwan (2006)" ///
1582012 "Taiwan (2012)" ///
1701997 "Colombia (1997)" ///
1701998 "Colombia (1998)" ///
1702005 "Colombia (2005)" ///
1702012 "Colombia (2012)" ///
1911996 "Croatia (1996)" ///
1911999 "Croatia (1999)" ///
1912008 "Croatia (2008)" ///
1962006 "Cyprus (2006)" ///
1962008 "Cyprus (2008)" ///
1962011 "Cyprus (2011)" ///
1972008 "Northern Cyprus (2008)" ///
2031990 "Czech Republic (1990)" ///
2031991 "Czech Republic (1991)" ///
2031998 "Czech Republic (1998)" ///
2031999 "Czech Republic (1999)" ///
2032008 "Czech Republic (2008)" ///
2081981 "Denmark (1981)" ///
2081990 "Denmark (1990)" ///
2081999 "Denmark (1999)" ///
2082008 "Denmark (2008)" ///
2141996 "Dominican Republic (1996)" ///
2182011 "Ecuador (2011)" ///
2182013 "Ecuador (2013)" ///
2221999 "El Salvador (1999)" ///
2312007 "Ethiopia (2007)" ///
2331990 "Estonia (1990)" ///
2331996 "Estonia (1996)" ///
2331999 "Estonia (1999)" ///
2332008 "Estonia (2008)" ///
2332011 "Estonia (2011)" ///
2461981 "Finland (1981)" ///
2461990 "Finland (1990)" ///
2461996 "Finland (1996)" ///
2462000 "Finland (2000)" ///
2462005 "Finland (2005)" ///
2462009 "Finland (2009)" ///
2501981 "France (1981)" ///
2501990 "France (1990)" ///
2501999 "France (1999)" ///
2502006 "France (2006)" ///
2502008 "France (2008)" ///
2681996 "Georgia (1996)" ///
2682008 "Georgia (2008)" ///
2682009 "Georgia (2009)" ///
2752013 "Palestine (2013)" ///
2761981 "Germany West (1981)" ///
2761990 "Germany (1990)" ///
2761997 "Germany (1997)" ///
2761999 "Germany (1999)" ///
2762006 "Germany (2006)" ///
2762008 "Germany (2008)" ///
2762013 "Germany (2013)" ///
2882007 "Ghana (2007)" ///
2882012 "Ghana (2012)" ///
3001999 "Greece (1999)" ///
3002008 "Greece (2008)" ///
3202004 "Guatemala (2004)" ///
3442005 "Hong Kong (2005)" ///
3481982 "Hungary (1982)" ///
3481991 "Hungary (1991)" ///
3481998 "Hungary (1998)" ///
3481999 "Hungary (1999)" ///
3482009 "Hungary (2009)" ///
3521984 "Iceland (1984)" ///
3521990 "Iceland (1990)" ///
3521999 "Iceland (1999)" ///
3522009 "Iceland (2009)" ///
3561990 "India (1990)" ///
3561995 "India (1995)" ///
3562001 "India (2001)" ///
3562006 "India (2006)" ///
3562012 "India (2012)" ///
3562014 "India (2014)" ///
3602001 "Indonesia (2001)" ///
3602006 "Indonesia (2006)" ///
3642000 "Iran (2000)" ///
3642007 "Iran (2007)" ///
3682004 "Iraq (2004)" ///
3682006 "Iraq (2006)" ///
3682012 "Iraq (2012)" ///
3721981 "Ireland (1981)" ///
3721990 "Ireland (1990)" ///
3721999 "Ireland (1999)" ///
3722008 "Ireland (2008)" ///
3762001 "Israel (2001)" ///
3801981 "Italy (1981)" ///
3801990 "Italy (1990)" ///
3801999 "Italy (1999)" ///
3802005 "Italy (2005)" ///
3802009 "Italy (2009)" ///
3921981 "Japan (1981)" ///
3921990 "Japan (1990)" ///
3921995 "Japan (1995)" ///
3922000 "Japan (2000)" ///
3922005 "Japan (2005)" ///
3922010 "Japan (2010)" ///
3982011 "Kazakhstan (2011)" ///
4002001 "Jordan (2001)" ///
4002007 "Jordan (2007)" ///
4002014 "Jordan (2014)" ///
4101982 "South Korea (1982)" ///
4101990 "South Korea (1990)" ///
4101996 "South Korea (1996)" ///
4102001 "South Korea (2001)" ///
4102005 "South Korea (2005)" ///
4102010 "South Korea (2010)" ///
4142014 "Kuwait (2014)" ///
4172003 "Kyrgyzstan (2003)" ///
4172011 "Kyrgyzstan (2011)" ///
4222013 "Lebanon (2013)" ///
4281990 "Latvia (1990)" ///
4281996 "Latvia (1996)" ///
4281999 "Latvia (1999)" ///
4282008 "Latvia (2008)" ///
4342014 "Libya (2014)" ///
4401990 "Lithuania (1990)" ///
4401997 "Lithuania (1997)" ///
4401999 "Lithuania (1999)" ///
4402008 "Lithuania (2008)" ///
4421999 "Luxembourg (1999)" ///
4422008 "Luxembourg (2008)" ///
4582006 "Malaysia (2006)" ///
4582012 "Malaysia (2012)" ///
4662007 "Mali (2007)" ///
4701983 "Malta (1983)" ///
4701991 "Malta (1991)" ///
4701999 "Malta (1999)" ///
4702008 "Malta (2008)" ///
4841981 "Mexico (1981)" ///
4841990 "Mexico (1990)" ///
4841995 "Mexico (1995)" ///
4841996 "Mexico (1996)" ///
4842000 "Mexico (2000)" ///
4842005 "Mexico (2005)" ///
4842012 "Mexico (2012)" ///
4981995 "Moldova (1995)" ///
4981996 "Moldova (1996)" ///
4982002 "Moldova (2002)" ///
4982006 "Moldova (2006)" ///
4982008 "Moldova (2008)" ///
4992008 "Montenegro (2008)" ///
5042001 "Morocco (2001)" ///
5042007 "Morocco (2007)" ///
5042011 "Morocco (2011)" ///
5281981 "Netherlands (1981)" ///
5281990 "Netherlands (1990)" ///
5281999 "Netherlands (1999)" ///
5282006 "Netherlands (2006)" ///
5282008 "Netherlands (2008)" ///
5282012 "Netherlands (2012)" ///
5541998 "New Zealand (1998)" ///
5542004 "New Zealand (2004)" ///
5542011 "New Zealand (2011)" ///
5661990 "Nigeria (1990)" ///
5661995 "Nigeria (1995)" ///
5662000 "Nigeria (2000)" ///
5662011 "Nigeria (2011)" ///
5781982 "Norway (1982)" ///
5781990 "Norway (1990)" ///
5781996 "Norway (1996)" ///
5782007 "Norway (2007)" ///
5782008 "Norway (2008)" ///
5861997 "Pakistan (1997)" ///
5862001 "Pakistan (2001)" ///
5862012 "Pakistan (2012)" ///
6041996 "Peru (1996)" ///
6042001 "Peru (2001)" ///
6042006 "Peru (2006)" ///
6042012 "Peru (2012)" ///
6081996 "Philippines (1996)" ///
6082001 "Philippines (2001)" ///
6082012 "Philippines (2012)" ///
6161989 "Poland (1989)" ///
6161990 "Poland (1990)" ///
6161997 "Poland (1997)" ///
6161999 "Poland (1999)" ///
6162005 "Poland (2005)" ///
6162008 "Poland (2008)" ///
6162012 "Poland (2012)" ///
6201990 "Portugal (1990)" ///
6201999 "Portugal (1999)" ///
6202008 "Portugal (2008)" ///
6301995 "Puerto Rico (1995)" ///
6302001 "Puerto Rico (2001)" ///
6342010 "Qatar (2010)" ///
6421993 "Romania (1993)" ///
6421998 "Romania (1998)" ///
6421999 "Romania (1999)" ///
6422005 "Romania (2005)" ///
6422008 "Romania (2008)" ///
6422012 "Romania (2012)" ///
6431990 "Russia (1990)" ///
6431995 "Russia (1995)" ///
6431999 "Russia (1999)" ///
6432006 "Russia (2006)" ///
6432008 "Russia (2008)" ///
6432011 "Russia (2011)" ///
6462007 "Rwanda (2007)" ///
6462012 "Rwanda (2012)" ///
6822003 "Saudi Arabia (2003)" ///
6882008 "Serbia (2008)" ///
7022002 "Singapore (2002)" ///
7022012 "Singapore (2012)" ///
7031990 "Slovakia (1990)" ///
7031991 "Slovakia (1991)" ///
7031998 "Slovakia (1998)" ///
7031999 "Slovakia (1999)" ///
7032008 "Slovak Republic (2008)" ///
7042001 "Viet Nam (2001)" ///
7042006 "Viet Nam (2006)" ///
7051992 "Slovenia (1992)" ///
7051995 "Slovenia (1995)" ///
7051999 "Slovenia (1999)" ///
7052005 "Slovenia (2005)" ///
7052008 "Slovenia (2008)" ///
7052011 "Slovenia (2011)" ///
7101982 "South Africa (1982)" ///
7101990 "South Africa (1990)" ///
7101996 "South Africa (1996)" ///
7102001 "South Africa (2001)" ///
7102006 "South Africa (2006)" ///
7102013 "South Africa (2013)" ///
7162001 "Zimbabwe (2001)" ///
7162012 "Zimbabwe (2012)" ///
7241981 "Spain (1981)" ///
7241990 "Spain (1990)" ///
7241995 "Spain (1995)" ///
7241999 "Spain (1999)" ///
7242000 "Spain (2000)" ///
7242007 "Spain (2007)" ///
7242008 "Spain (2008)" ///
7242011 "Spain (2011)" ///
7521981 "Sweden (1981)" ///
7521982 "Sweden (1982)" ///
7521990 "Sweden (1990)" ///
7521996 "Sweden (1996)" ///
7521999 "Sweden (1999)" ///
7522006 "Sweden (2006)" ///
7522009 "Sweden (2009)" ///
7522011 "Sweden (2011)" ///
7561989 "Switzerland (1989)" ///
7561996 "Switzerland (1996)" ///
7562007 "Switzerland (2007)" ///
7562008 "Switzerland (2008)" ///
7642007 "Thailand (2007)" ///
7642013 "Thailand (2013)" ///
7802006 "Trinidad and Tobago (2006)" ///
7802011 "Trinidad and Tobago (2011)" ///
7882013 "Tunisia (2013)" ///
7921990 "Turkey (1990)" ///
7921996 "Turkey (1996)" ///
7922001 "Turkey (2001)" ///
7922007 "Turkey (2007)" ///
7922009 "Turkey (2009)" ///
7922011 "Turkey (2011)" ///
8002001 "Uganda (2001)" ///
8041996 "Ukraine (1996)" ///
8041999 "Ukraine (1999)" ///
8042006 "Ukraine (2006)" ///
8042008 "Ukraine (2008)" ///
8042011 "Ukraine (2011)" ///
8071998 "Macedonia (1998)" ///
8072001 "Macedonia (2001)" ///
8072008 "Macedonia (2008)" ///
8182000 "Egypt (2000)" ///
8182001 "Egypt (2001)" ///
8182008 "Egypt (2008)" ///
8182013 "Egypt (2013)" ///
8261981 "UK (1981)" ///
8261990 "UK (1990)" ///
8261995 "UK (1995)" ///
8261998 "UK (1998)" ///
8261999 "UK (1999)" ///
8262005 "UK (2005)" ///
8262009 "UK (2009)" ///
8342001 "Tanzania (2001)" ///
8401981 "United States (1981)" ///
8401982 "United States (1982)" ///
8401990 "United States (1990)" ///
8401995 "United States (1995)" ///
8401999 "United States (1999)" ///
8402006 "United States (2006)" ///
8402011 "United States (2011)" ///
8542007 "Burkina Faso (2007)" ///
8581996 "Uruguay (1996)" ///
8582006 "Uruguay (2006)" ///
8582011 "Uruguay (2011)" ///
8602011 "Uzbekistan (2011)" ///
8621996 "Venezuela (1996)" ///
8622000 "Venezuela (2000)" ///
8872014 "Yemen (2014)" ///
8911996 "Serbia and Montenegro (1996)" ///
8912001 "Serbia and Montenegro (2001)" ///
8912005 "Serbia and Montenegro (2005)" ///
8942007 "Zambia (2007)" ///
9091981 "Northern Ireland (1981)" ///
9091990 "Northern Ireland (1990)" ///
9091999 "Northern Ireland (1999)" ///
9092008 "Northern Ireland (2008)" ///
9111996 "Serbia (1996)" ///
9112001 "Serbia (2001)" ///
9112006 "Serbia (2006)" ///
9121996 "Montenegro (1996)" ///
9122001 "Montenegro (2001)" ///
9152008 "Kosovo (2008)" ///
9141998 "Bosnia (1998)" ///
82018 "Albania (2018)" ///
82021 "Latvia (2021)" ///
202018 "Andorra (2018)" ///
4342022 "Libya (2022)" ///
312018 "Azerbaijan (2018)" ///
4402018 "Lithuania (2018)" ///
322017 "Argentina (2017)" ///
4462020 "Macau SAR (2020)" ///
362018 "Australia (2018)" ///
4582018 "Malaysia (2018)" ///
402018 "Austria (2018)" ///
4622021 "Maldives (2021)" ///
502018 "Bangladesh (2018)" ///
4842018 "Mexico (2018)" ///
512018 "Armenia (2018)" ///
4962020 "Mongolia (2020)" ///
512021 "Armenia (2021)" ///
4992019 "Montenegro (2019)" ///
682017 "Bolivia (2017)" ///
5042021 "Morocco (2021)" ///
702019 "Bosnia and Herzegovina (2019)" ///
5282017 "Netherlands (2017)" ///
762018 "Brazil (2018)" ///
5282022 "Netherlands (2022)" ///
1002017 "Bulgaria (2017)" ///
5542020 "New Zealand (2020)" ///
1042020 "Myanmar (2020)" ///
5582020 "Nicaragua (2020)" ///
1122018 "Belarus (2018)" ///
5662018 "Nigeria (2018)" ///
1242020 "Canada (2020)" ///
5782018 "Norway (2018)" ///
1522018 "Chile (2018)" ///
5862018 "Pakistan (2018)" ///
1562018 "China (2018)" ///
6042018 "Peru (2018)" ///
1582019 "Taiwan ROC (2019)" ///
6082019 "Philippines (2019)" ///
1702018 "Colombia (2018)" ///
6162017 "Poland (2017)" ///
1912017 "Croatia (2017)" ///
6202020 "Portugal (2020)" ///
1962019 "Cyprus (2019)" ///
6302018 "Puerto Rico (2018)" ///
2032017 "Czechia (2017)" ///
6422018 "Romania (2018)" ///
2032022 "Czechia (2022)" ///
6432017 "Russia (2017)" ///
2082017 "Denmark (2017)" ///
6882017 "Serbia (2017)" ///
2182018 "Ecuador (2018)" ///
6882018 "Serbia (2018)" ///
2312020 "Ethiopia (2020)" ///
7022020 "Singapore (2020)" ///
2332018 "Estonia (2018)" ///
7032017 "Slovakia (2017)" ///
2462017 "Finland (2017)" ///
7032022 "Slovakia (2022)" ///
2502018 "France (2018)" ///
7042020 "Vietnam (2020)" ///
2682018 "Georgia (2018)" ///
7052017 "Slovenia (2017)" ///
2762017 "Germany (2017)" ///
7162020 "Zimbabwe (2020)" ///
2762018 "Germany (2018)" ///
7242017 "Spain (2017)" ///
3002017 "Greece (2017)" ///
7522017 "Sweden (2017)" ///
3202020 "Guatemala (2020)" ///
7562017 "Switzerland (2017)" ///
3442018 "Hong Kong SAR (2018)" ///
7622020 "Tajikistan (2020)" ///
3482018 "Hungary (2018)" ///
7642018 "Thailand (2018)" ///
3522017 "Iceland (2017)" ///
7882019 "Tunisia (2019)" ///
3602018 "Indonesia (2018)" ///
7922018 "Turkey (2018)" ///
3562023 "India (2023)" ///
8042020 "Ukraine (2020)" ///
3642020 "Iran (2020)" ///
8072019 "North Macedonia (2019)" ///
3682018 "Iraq (2018)" ///
8182018 "Egypt (2018)" ///
3802018 "Italy (2018)" ///
8262018 "UK (2018)" ///
3922019 "Japan (2019)" ///
8262022 "UK (2022)" ///
3982018 "Kazakhstan (2018)" ///
8402017 "United States (2017)" ///
4002018 "Jordan (2018)" ///
8582022 "Uruguay (2022)" ///
4042021 "Kenya (2021)" ///
8602022 "Uzbekistan (2022)" ///
4102018 "South Korea (2018)" ///
8622021 "Venezuela (2021)" ///
4172020 "Kyrgyzstan (2020)" ///
9092022 "Northern Ireland (2022)" ///
4222018 "Lebanon (2018)" 

label values Country_year countrylbl

foreach var in abortion_justif Ideal_Child duty_children {
    replace `var' = . if inlist(`var', -5, -4, -3, -2, -1)
}

replace Type_of_habitat = . if inlist(Type_of_habitat, -5, -4, -3, -2, -1)
label define urbanicity_lbl ///
    1 "Rural area-village" ///
    2 "Small-medium town" ///
    3 "Large town", replace

label values Type_of_habitat urbanicity_lbl

label def Sex 1"Male" 2"Female", replace
label values Sex Sex


label def marital_stat 1 "Married" 2 "Living together as married" 3 "Divorced" 4 "Separated" 5 "Widowed" 6 "Single/Never married" 7 "Divorced, Separated or Widow" 8 "Living apart but steady relation (married,cohabitation)" , replace

label values marital_stat marital_stat
replace marital_stat = . if inlist(marital_stat, -5, -4, -3, -2, -1)

ologit abortion_justif i.duty_children Sex

log close

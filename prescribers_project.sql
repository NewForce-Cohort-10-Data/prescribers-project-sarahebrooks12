select * from prescriber;
select * from prescription;
select * from population;
select * from overdose_deaths;
select * from drug;
select * from cbsa;
select * from population;
select * from fips_county;


-- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
Select npi, SUM(total_claim_count) as total_claims
from prescription
group by npi
order by total_claims DESC;

-- NPI: 1881634483
-- Claims: 99707

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
Select SUM(p.total_claim_count) as total_claims, pdr.nppes_provider_first_name, pdr.nppes_provider_last_org_name, pdr.specialty_description
from prescriber as pdr
inner join prescription as p
on p.npi = pdr.npi
group by pdr.nppes_provider_first_name, pdr.nppes_provider_last_org_name, pdr.specialty_description
order by total_claims DESC;

-- Name: Bruce Pendley
-- Specialty: Family Practice
-- Claims: 99707

-- a. Which specialty had the most total number of claims (totaled over all drugs)?
Select DISTINCT pdr.specialty_description, SUM(p.total_claim_count) as total_claims
from prescriber as pdr
inner join prescription as p
on p.npi = pdr.npi
group by pdr.specialty_description
order by total_claims DESC;

-- Family Practice
-- 9752347

-- b. Which specialty had the most total number of claims for opioids?
Select DISTINCT pdr.specialty_description, SUM(p.total_claim_count) as total_claims
from prescriber as pdr
inner join prescription as p
on p.npi = pdr.npi
inner join drug as d
on d.drug_name = p.drug_name
where d.opioid_drug_flag = 'Y'
group by pdr.specialty_description
order by total_claims DESC;

-- Nurse Practioner
-- Claims: 900845

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
Select DISTINCT pdr.specialty_description
from prescriber as pdr
full join prescription as p
on p.npi = pdr.npi
where p.npi is null
group by pdr.specialty_description;

-- 92

-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
with opioids_numbers as 
(Select DISTINCT pdr.specialty_description,
SUM(CASE when d.opioid_drug_flag = 'Y' then p.total_claim_count else 0 end) as opioid_claims
from prescriber as pdr
inner join prescription as p
on p.npi = pdr.npi
inner join drug as d
on d.drug_name = p.drug_name
where d.opioid_drug_flag = 'Y'
group by pdr.specialty_description)

Select ROUND((SUM(p.total_claim_count) / opioid_claims) , 2), specialty_description
from prescription as p
inner join prescriber as pdr
using (npi)
inner join opioids_numbers
using (specialty_description)
group by opioid_claims, specialty_description
order by round DESC;

-- Chris
SELECT 
specialty_description,
ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END)/ SUM(total_claim_count) * 100 ,2) AS percent_opioid_claims
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)	
GROUP BY specialty_description
ORDER BY percent_opioid_claims  DESC NULLS LAST;

-- a. Which drug (generic_name) had the highest total drug cost?
Select d.generic_name, total_drug_cost::numeric as drug_cost
from prescription as p
inner join drug as d
on d.drug_name = p.drug_name
order by drug_cost DESC;

-- Generic Name: PIRFENIDONE
-- Cost: 2829174.3

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
Select DISTINCT d.generic_name, ROUND(SUM(total_drug_cost::numeric) / 365, 2) as drug_cost
from prescription as p
inner join drug as d
on d.drug_name = p.drug_name
group by d.generic_name
order by drug_cost DESC;

-- Drug: INSULIN GLARGINE,HUM.REC.ANLOG
-- Cost per day: 285654.98

Select d.generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) as cost_per_day
from prescription as p
inner join drug as d
on d.drug_name = p.drug_name
group by d.generic_name
order by cost_per_day DESC;

-- Generic Name: C1 ESTERASE INHIBITOR
-- Daily Cost: 3495.22

-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
Select DISTINCT drug_name,
CASE when opioid_drug_flag = 'Y' then 'opioid'
when antibiotic_drug_flag = 'Y' then 'antibiotic'
else 'neither' end
from drug
order by drug_name;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
with drug_cost as (Select DISTINCT d.drug_name,
SUM(CASE when d.opioid_drug_flag = 'Y' then p.total_drug_cost else 0 end)::money as opioid_cost,
SUM(CASE when d.antibiotic_drug_flag = 'Y' then p.total_drug_cost else 0 end)::money as antibiotic_cost
from drug as d
inner join prescription as p
on p.drug_name = d.drug_name
group by d.drug_name)
Select SUM(opioid_cost) as opioid_money_total, SUM(antibiotic_cost) as antibiotic_money_total
from drug_cost;

-- Opioid: $105,080,626.37
-- Antibiotic: $38,435,121.26
-- Opioid 

-- a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
Select COUNT(cbsa)
from cbsa
where cbsaname ilike '%TN%';

--58

Select COUNT(c.cbsa)
from cbsa as c
inner join fips_county as f
on f.fipscounty = c.fipscounty
where f.state = 'TN';

--42

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
Select c.cbsa, p.population, c.cbsaname
from cbsa as c
inner join population as p
on p.fipscounty = c.fipscounty
order by p.population;

-- Largest: 32820 - 937847 - Memphis, TN-MS-AR
-- Smallest: 34980 - 13839 - Nashville-Davidson--Murfreesboro--Franklin, TN

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
Select p.population, f.county
from cbsa as c
full join population as p
USING(fipscounty)
full join fips_county as f
USING(fipscounty)
where c.cbsa is null and population is not null
order by p.population DESC;

-- County: Sevier
-- 95523

-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
Select drug_name, SUM(total_claim_count) as total_claims
from prescription
where total_claim_count >= 3000
group by drug_name
order by total_claims DESC;

-- 7 rows

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
Select drug_name, SUM(total_claim_count) as total_claims, (CASE when opioid_drug_flag = 'Y' then 'opioid' else '' end) as type
from prescription
inner join drug
using (drug_name)
where total_claim_count >= 3000
group by drug_name, opioid_drug_flag
order by total_claims DESC;

-- Drugs: Oxycodone HCL, HYDROCODONE-ACETAMINOPHEN

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
Select drug_name, SUM(total_claim_count) as total_claims, (CASE when opioid_drug_flag = 'Y' then 'opioid' else '' end) as type,  nppes_provider_first_name, nppes_provider_last_org_name
from prescription
inner join drug
using (drug_name)
inner join prescriber
using (npi)
where total_claim_count >= 3000
group by drug_name, opioid_drug_flag, nppes_provider_first_name, nppes_provider_last_org_name
order by total_claims DESC;




-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
Select d.drug_name, pdr.npi
from prescriber as pdr
cross join drug as d
where pdr.specialty_description = 'Pain Management'
AND pdr.nppes_provider_city = 'NASHVILLE'
AND d.opioid_drug_flag = 'Y'
order by d.drug_name;

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
Select p.npi, d.drug_name, SUM(total_claim_count)
from prescription as p
inner join drug as d
using (drug_name)
inner join prescriber as pdr
using (npi)
where pdr.specialty_description = 'Pain Management'
AND pdr.nppes_provider_city = 'NASHVILLE'
AND d.opioid_drug_flag = 'Y'
group by p.npi, d.drug_name
order by p.npi;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


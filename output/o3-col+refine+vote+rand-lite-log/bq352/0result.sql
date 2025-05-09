-- Average 2018 prenatal-weeks for Wisconsin counties that have
-- at least one ZIP code (ZCTA) where >5 % of workers commute 45–59 minutes
WITH wi_zips_high_commute AS (          -- 1. “High-commute” WI ZIP codes
  SELECT CAST(`geo_id` AS STRING) AS zip
  FROM `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr`
  WHERE REGEXP_EXTRACT(`geo_id`, r'^(\d{2})') IN ('53','54')            -- WI ZIP prefixes
    AND SAFE_DIVIDE(`commute_45_59_mins`, `employed_pop`) > 0.05
),
qualified_wi_counties AS (             -- 2. All WI counties appearing in natality data
  SELECT DISTINCT `County_of_Residence`
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE `County_of_Residence` LIKE '%, WI'
)
SELECT                                     -- 3. Average prenatal weeks in 2018
  n.`County_of_Residence`,
  AVG(n.`Ave_Number_of_Prenatal_Wks`) AS avg_prenatal_wks_2018
FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity` AS n
WHERE EXTRACT(YEAR FROM n.`Year`) = 2018
  AND n.`County_of_Residence` IN (SELECT `County_of_Residence` FROM qualified_wi_counties)
GROUP BY n.`County_of_Residence`
ORDER BY avg_prenatal_wks_2018 DESC;
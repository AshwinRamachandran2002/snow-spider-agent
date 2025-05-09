-- average prenatal weeks (2018) for WI counties where >5% of employed pop
-- had 45–59‑minute commutes in 2017
WITH eligible_counties AS (
  SELECT
    geo_id AS county_fips
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE
    SUBSTR(geo_id, 1, 2) = '55'                -- Wisconsin state FIPS = 55
    AND employed_pop > 0
    AND SAFE_DIVIDE(commute_45_59_mins, employed_pop) > 0.05
)
SELECT
  AVG(n.Ave_Number_of_Prenatal_Wks) AS avg_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  eligible_counties AS ec
ON
  n.County_of_Residence_FIPS = ec.county_fips
WHERE
  n.Year = '2018-01-01'
  AND n.Ave_Number_of_Prenatal_Wks IS NOT NULL;
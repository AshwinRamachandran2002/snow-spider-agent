WITH commute_share_over_5 AS (
  -- 1. 2017 ACS: Wisconsin counties whose 45–59-minute commuters exceed 5 % of employed population
  SELECT
    SUBSTR(`geo_id`, 1, 5) AS county_fips,
    SAFE_DIVIDE(SUM(`commute_45_59_mins`), SUM(`employed_pop`)) AS commute_share
  FROM `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr`
  WHERE `geo_id` LIKE '55%'                    -- Wisconsin ZCTAs
  GROUP BY county_fips
  HAVING commute_share > 0.05                  -- > 5 %
),
wi_natality_2018 AS (
  -- 2. 2018 CDC natality records for Wisconsin
  SELECT
    `County_of_Residence`,
    `County_of_Residence_FIPS` AS county_fips,
    `Ave_Number_of_Prenatal_Wks`
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE `Year` = '2018-01-01'
    AND `County_of_Residence` LIKE '%, WI'     -- Wisconsin counties
    AND `Ave_Number_of_Prenatal_Wks` IS NOT NULL
)
-- 3. Join the two datasets and report the average prenatal weeks (4-decimal precision)
SELECT
  n.`County_of_Residence`,
  ROUND(AVG(n.`Ave_Number_of_Prenatal_Wks`), 4) AS avg_prenatal_weeks_2018
FROM wi_natality_2018 AS n
JOIN commute_share_over_5 AS c
  ON n.county_fips = c.county_fips
GROUP BY n.`County_of_Residence`
ORDER BY avg_prenatal_weeks_2018 DESC;
WITH commute AS (
  SELECT
    geo_id AS county_fips,
    commute_45_59_mins,
    employed_pop
  FROM `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE SUBSTR(geo_id, 1, 2) = '55'   -- Wisconsin counties
),
commute_flag AS (          -- counties with >5% commuting 45–59 minutes
  SELECT
    county_fips
  FROM commute
  WHERE employed_pop > 0
    AND SAFE_DIVIDE(commute_45_59_mins, employed_pop) > 0.05
),
prenatal AS (              -- 2018 average prenatal weeks
  SELECT
    County_of_Residence_FIPS AS county_fips,
    AVG(Ave_Number_of_Prenatal_Wks) AS avg_prenatal_weeks
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) = 2018
    AND SUBSTR(County_of_Residence_FIPS, 1, 2) = '55'
    AND Ave_Number_of_Prenatal_Wks IS NOT NULL
  GROUP BY County_of_Residence_FIPS
)
SELECT
  p.county_fips,
  p.avg_prenatal_weeks
FROM prenatal p
JOIN commute_flag c
  ON p.county_fips = c.county_fips
ORDER BY p.avg_prenatal_weeks DESC;
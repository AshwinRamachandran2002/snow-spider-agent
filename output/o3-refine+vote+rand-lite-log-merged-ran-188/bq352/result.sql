-- Average prenatal weeks (2018) for WI counties where >5% of workers commuted 45‑59 minutes in 2017
WITH commute_criteria AS (
  SELECT
    geo_id AS county_fips,
    SAFE_CAST(commute_45_59_mins AS FLOAT64) /
    NULLIF(SAFE_CAST(employed_pop AS FLOAT64),0) AS pct_long_commute
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE
    SUBSTR(geo_id,1,2) = '55'          -- Wisconsin state FIPS
)
, selected_counties AS (
  SELECT county_fips
  FROM commute_criteria
  WHERE pct_long_commute > 0.05        -- more than 5 %
)

SELECT
  n.County_of_Residence_FIPS                          AS county_fips,
  n.County_of_Residence                               AS county_name,
  AVG(n.Ave_Number_of_Prenatal_Wks) AS avg_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` n
JOIN
  selected_counties sc
ON
  n.County_of_Residence_FIPS = sc.county_fips
WHERE
  EXTRACT(YEAR FROM n.Year) = 2018
GROUP BY
  county_fips,
  county_name
ORDER BY
  county_fips;
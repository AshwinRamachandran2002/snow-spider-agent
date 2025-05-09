WITH commute_2017 AS (
  SELECT
    geo_id                                      AS county_fips,
    SAFE_DIVIDE(commute_45_59_mins, employed_pop) * 100 AS pct_commute_45_59
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE LEFT(geo_id, 2) = '55'                               -- Wisconsin counties
),
wi_counties_commute_gt5 AS (
  SELECT county_fips
  FROM commute_2017
  WHERE pct_commute_45_59 > 5                                -- more than 5 % commuting 45‑59 minutes
),
prenatal_2018 AS (
  SELECT
    County_of_Residence_FIPS AS county_fips,
    County_of_Residence      AS county_name,
    Ave_Number_of_Prenatal_Wks
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) = 2018                        -- year 2018
    AND LEFT(County_of_Residence_FIPS, 2) = '55'              -- Wisconsin counties
)
SELECT
  p.county_fips,
  p.county_name,
  ROUND(AVG(p.Ave_Number_of_Prenatal_Wks), 2) AS avg_prenatal_weeks_2018
FROM prenatal_2018 p
JOIN wi_counties_commute_gt5 c
  ON p.county_fips = c.county_fips
GROUP BY p.county_fips, p.county_name
ORDER BY p.county_name;
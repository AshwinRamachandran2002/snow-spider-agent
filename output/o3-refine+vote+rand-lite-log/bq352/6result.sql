WITH commuting AS (
  SELECT
    geo_id AS county_fips,
    commute_45_59_mins,
    employed_pop,
    SAFE_DIVIDE(commute_45_59_mins, employed_pop) AS pct_commute_45_59
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE
    LEFT(geo_id, 2) = '55'         -- Wisconsin state FIPS
    AND employed_pop > 0
),
eligible_counties AS (
  SELECT
    county_fips
  FROM
    commuting
  WHERE
    pct_commute_45_59 > 0.05       -- more than 5% commuting 45–59 mins
)

SELECT
  AVG(Ave_Number_of_Prenatal_Wks) AS avg_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  eligible_counties AS e
ON
  n.County_of_Residence_FIPS = e.county_fips
WHERE
  EXTRACT(YEAR FROM n.Year) = 2018;
WITH commute AS (
  SELECT
    geo_id AS county_fips,
    commute_45_59_mins,
    employed_pop
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE
    SUBSTR(geo_id, 1, 2) = '55'                  -- Wisconsin counties (FIPS prefix 55)
    AND employed_pop IS NOT NULL
    AND employed_pop > 0
),
eligible AS (
  SELECT
    county_fips
  FROM
    commute
  WHERE
    SAFE_DIVIDE(commute_45_59_mins, employed_pop) > 0.05   -- > 5 % commuting 45‑59 minutes
)

SELECT
  n.County_of_Residence_FIPS   AS county_fips,
  n.County_of_Residence        AS county_name,
  n.Ave_Number_of_Prenatal_Wks AS avg_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  eligible AS e
ON
  n.County_of_Residence_FIPS = e.county_fips
WHERE
  n.Year = '2018-01-01'                             -- 2018 data
ORDER BY
  county_name;
WITH counties_long_commute AS (
  SELECT
    geo_id AS county_fips
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE
    -- Wisconsin counties (state FIPS 55)
    geo_id LIKE '55%'
    -- avoid division by zero
    AND employed_pop IS NOT NULL
    AND employed_pop > 0
    -- more than 5 % of employed population has 45–59‑minute commute
    AND (commute_45_59_mins / employed_pop) > 0.05
)

SELECT
  n.County_of_Residence_FIPS          AS county_fips,
  n.County_of_Residence               AS county_name,
  AVG(n.Ave_Number_of_Prenatal_Wks)   AS avg_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  counties_long_commute AS c
ON
  n.County_of_Residence_FIPS = c.county_fips
WHERE
  n.Year = '2018-01-01'         -- natality data for 2018
GROUP BY
  county_fips,
  county_name
ORDER BY
  county_fips;
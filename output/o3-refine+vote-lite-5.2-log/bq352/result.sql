WITH commute AS (
  SELECT
    geo_id,
    SUBSTR(geo_id, 1, 2)   AS state_fips,
    SUBSTR(geo_id, 3, 3)   AS county_fips,
    commute_45_59_mins,
    employed_pop,
    SAFE_DIVIDE(commute_45_59_mins, NULLIF(employed_pop, 0)) * 100 AS pct_commute_45_59
  FROM
    `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE
    SUBSTR(geo_id, 1, 2) = '55'        -- Wisconsin
),
qualifying_counties AS (
  SELECT
    CONCAT(state_fips, county_fips) AS fips
  FROM
    commute
  WHERE
    pct_commute_45_59 > 5            -- >5% commuting 45–59 minutes
)

SELECT
  n.County_of_Residence            AS county_name,
  n.Ave_Number_of_Prenatal_Wks     AS avg_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  qualifying_counties qc
ON
  n.County_of_Residence_FIPS = qc.fips
WHERE
  n.Year = '2018-01-01'
ORDER BY
  avg_prenatal_weeks_2018 DESC;
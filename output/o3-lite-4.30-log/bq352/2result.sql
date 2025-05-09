SELECT
  n.County_of_Residence            AS county,
  ROUND(n.Ave_Number_of_Prenatal_Wks, 4) AS average_prenatal_weeks_2018
FROM
  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN
  `bigquery-public-data.census_bureau_acs.county_2017_1yr`        AS a
ON
  n.County_of_Residence_FIPS = a.geo_id
WHERE
  n.Year = '2018-01-01'                       -- 2018 natality data
  AND LEFT(a.geo_id, 2) = '55'                -- Wisconsin counties
  AND a.commute_45_59_mins / a.employed_pop > 0.05   -- >5% commuting 45–59 minutes
ORDER BY
  county;
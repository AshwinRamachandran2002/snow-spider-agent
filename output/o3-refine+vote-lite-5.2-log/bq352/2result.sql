WITH commute_filter AS (
  SELECT
    CAST(geo_id AS STRING)           AS county_fips,
    SAFE_DIVIDE(
      CAST(commute_45_59_mins AS FLOAT64),
      NULLIF(CAST(employed_pop        AS FLOAT64),0)
    )                                AS pct_commute_45_59
  FROM `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE SUBSTR(geo_id,1,2) = '55'            -- Wisconsin
)
SELECT
  n.County_of_Residence            AS county_name,
  n.Ave_Number_of_Prenatal_Wks     AS avg_prenatal_weeks
FROM  `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`  AS n
JOIN  commute_filter AS c
      ON n.County_of_Residence_FIPS = c.county_fips
WHERE n.Year = '2018-01-01'
  AND c.pct_commute_45_59 > 0.05     -- >5% commuting 45–59 minutes
ORDER BY avg_prenatal_weeks DESC;
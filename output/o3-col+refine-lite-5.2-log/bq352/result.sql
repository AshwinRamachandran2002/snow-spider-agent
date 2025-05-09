-- Average prenatal weeks (2018) for WI counties where >5% of 2017 commuters travel 45‑59 mins
WITH wi_commute_ok AS (
  SELECT
    geo_id AS county_fips,
    SAFE_DIVIDE(commute_45_59_mins, employed_pop) AS pct_commute_45_59
  FROM `bigquery-public-data.census_bureau_acs.county_2017_1yr`
  WHERE LEFT(geo_id, 2) = '55'                       -- Wisconsin FIPS prefix
    AND SAFE_DIVIDE(commute_45_59_mins, employed_pop) > 0.05
)

SELECT
  n.County_of_Residence_FIPS              AS county_fips,
  AVG(n.Ave_Number_of_Prenatal_Wks)       AS avg_prenatal_weeks_2018
FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality` AS n
JOIN wi_commute_ok AS c
  ON n.County_of_Residence_FIPS = c.county_fips
WHERE EXTRACT(YEAR FROM n.Year) = 2018
GROUP BY county_fips
ORDER BY county_fips;
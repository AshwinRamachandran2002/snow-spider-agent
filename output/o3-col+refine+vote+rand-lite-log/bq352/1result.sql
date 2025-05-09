-- Average 2018 prenatal weeks for Wisconsin counties
-- shown only if >5% of WI workers had 45-59-minute commutes in 2017
WITH wi_commute_share AS (
  SELECT
    SUM(commute_45_59_mins) / SUM(employed_pop) AS pct_45_59_mins
  FROM `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr`
  -- Wisconsin ZIP/ZCTA codes range from 53000–54999
  WHERE SAFE_CAST(geo_id AS INT64) BETWEEN 53000 AND 54999
)
SELECT
  n.County_of_Residence,
  ROUND(AVG(n.Ave_Number_of_Prenatal_Wks), 2) AS avg_prenatal_wks_2018
FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity` AS n
JOIN wi_commute_share s
  ON s.pct_45_59_mins > 0.05            -- retain results only if commute share >5 %
WHERE EXTRACT(YEAR FROM n.Year) = 2018  -- focus on 2018 births
  AND n.County_of_Residence LIKE '%, WI'
GROUP BY n.County_of_Residence
ORDER BY n.County_of_Residence;
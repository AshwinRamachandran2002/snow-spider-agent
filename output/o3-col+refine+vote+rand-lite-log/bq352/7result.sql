-- Average 2018 prenatal weeks for Wisconsin counties, returned only if
-- more than 5 % of the state’s employed population had 45-59-minute commutes in 2017
WITH wi_commute AS (
  SELECT
    100 * SUM(commute_45_59_mins) / SUM(employed_pop) AS pct_commute_45_59
  FROM `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr`
  WHERE SAFE_CAST(geo_id AS INT64) BETWEEN 53000 AND 54999          -- Wisconsin ZIP range
),
wi_prenatal_2018 AS (
  SELECT
    County_of_Residence,
    AVG(Ave_Number_of_Prenatal_Wks) AS avg_prenatal_wks_2018
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM `Year`) = 2018
    AND County_of_Residence LIKE '%, WI'                             -- Wisconsin counties
  GROUP BY County_of_Residence
)
SELECT
  p.County_of_Residence,
  p.avg_prenatal_wks_2018
FROM wi_prenatal_2018 AS p
JOIN wi_commute AS c
ON c.pct_commute_45_59 > 5                                          -- apply > 5 % rule
ORDER BY p.avg_prenatal_wks_2018 DESC;
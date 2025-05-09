/*  Average 2018 prenatal-care weeks for Wisconsin counties
    where more than 5 % of 2017 workers had 45- to 59-minute commutes          */

WITH wi_commute_ok AS (
  SELECT
    CAST(geo_id AS INT64)                             AS county_fips,
    SAFE_DIVIDE(SUM(commute_45_59_mins),
                SUM(employed_pop))                    AS pct_comm_45_59
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE CAST(geo_id AS INT64) BETWEEN 55000 AND 55999       -- Wisconsin
        AND employed_pop > 0
  GROUP BY county_fips
  HAVING pct_comm_45_59 > 0.05                            -- > 5 % commuters
),
wi_prenatal_2018 AS (
  SELECT
    County_of_Residence,
    CAST(County_of_Residence_FIPS AS INT64)            AS county_fips,
    Ave_Number_of_Prenatal_Wks
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) = 2018
        AND County_of_Residence LIKE '%, WI'
)
SELECT
  p.County_of_Residence,
  ROUND(AVG(p.Ave_Number_of_Prenatal_Wks), 4) AS avg_prenatal_wks_2018
FROM wi_prenatal_2018 AS p
JOIN wi_commute_ok  AS c
  ON p.county_fips = c.county_fips
GROUP BY p.County_of_Residence
ORDER BY p.County_of_Residence;
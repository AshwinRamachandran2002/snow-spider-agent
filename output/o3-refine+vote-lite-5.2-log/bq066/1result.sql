-- Pearson correlation between county‑level poverty rate (from prior‑year ACS 5‑yr file)
-- and percent of births without reported maternal morbidity, for 2016‑2018
WITH poverty AS (   -- poverty rate from PRIOR‑YEAR ACS 5‑year county file
  SELECT '2016' AS yr , geo_id AS fips ,
         SAFE_DIVIDE(poverty , total_pop) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE total_pop > 0
  UNION ALL
  SELECT '2017', geo_id , SAFE_DIVIDE(poverty , total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  WHERE total_pop > 0
  UNION ALL
  SELECT '2018', geo_id , SAFE_DIVIDE(poverty , total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE total_pop > 0
),
births_no_morb AS (   -- births where NO maternal morbidity was reported
  SELECT
    FORMAT_DATE('%Y', Year) AS yr ,
    County_of_Residence_FIPS AS fips ,
    SUM(Births) AS births_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE Maternal_Morbidity_Desc = 'None checked'
    AND Maternal_Morbidity_YN = 1
    AND FORMAT_DATE('%Y', Year) IN ('2016','2017','2018')
  GROUP BY yr , fips
),
births_total AS (     -- total births per county & year
  SELECT
    FORMAT_DATE('%Y', Year) AS yr ,
    County_of_Residence_FIPS AS fips ,
    SUM(Births) AS total_births
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE FORMAT_DATE('%Y', Year) IN ('2016','2017','2018')
  GROUP BY yr , fips
),
pct_clean AS (        -- percent of births with no maternal morbidity
  SELECT
    t.yr ,
    t.fips ,
    SAFE_DIVIDE(n.births_no_morbidity , t.total_births) AS pct_no_morbidity
  FROM births_total t
  JOIN births_no_morb n
    ON  t.yr  = n.yr
   AND t.fips = n.fips
)
SELECT
  p.yr  AS year ,
  CORR(p.poverty_rate , c.pct_no_morbidity) AS pearson_correlation
FROM poverty p
JOIN pct_clean c
  ON p.yr  = c.yr
 AND p.fips = c.fips
GROUP BY year
ORDER BY year;
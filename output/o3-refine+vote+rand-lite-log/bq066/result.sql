WITH
/* ---------- 2016 births  | 2015 5‑year ACS ---------- */
year_2016 AS (
  SELECT
    2016 AS yr,
    SAFE_DIVIDE(c.poverty, NULLIF(c.pop_determined_poverty_status,0))       AS poverty_rate,
    SAFE_DIVIDE(none.births, tot.births)                                     AS pct_no_morbidity
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr` AS c
  JOIN (      -- total births 2016
        SELECT County_of_Residence_FIPS AS fips, SUM(Births) AS births
        FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
        WHERE Year = '2016-01-01'
        GROUP BY fips)                 AS tot          ON tot.fips  = c.geo_id
  JOIN (      -- births with NO maternal morbidity 2016
        SELECT County_of_Residence_FIPS AS fips, SUM(Births) AS births
        FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
        WHERE Year = '2016-01-01'
          AND Maternal_Morbidity_Desc = 'None checked'
        GROUP BY fips)                 AS none         ON none.fips = c.geo_id
  WHERE c.poverty IS NOT NULL AND c.pop_determined_poverty_status > 0
),

/* ---------- 2017 births  | 2016 5‑year ACS ---------- */
year_2017 AS (
  SELECT
    2017 AS yr,
    SAFE_DIVIDE(c.poverty, NULLIF(c.pop_determined_poverty_status,0))       AS poverty_rate,
    SAFE_DIVIDE(none.births, tot.births)                                     AS pct_no_morbidity
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr` AS c
  JOIN (
        SELECT County_of_Residence_FIPS AS fips, SUM(Births) AS births
        FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
        WHERE Year = '2017-01-01'
        GROUP BY fips)                 AS tot          ON tot.fips  = c.geo_id
  JOIN (
        SELECT County_of_Residence_FIPS AS fips, SUM(Births) AS births
        FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
        WHERE Year = '2017-01-01'
          AND Maternal_Morbidity_Desc = 'None checked'
        GROUP BY fips)                 AS none         ON none.fips = c.geo_id
  WHERE c.poverty IS NOT NULL AND c.pop_determined_poverty_status > 0
),

/* ---------- 2018 births  | 2017 5‑year ACS ---------- */
year_2018 AS (
  SELECT
    2018 AS yr,
    SAFE_DIVIDE(c.poverty, NULLIF(c.pop_determined_poverty_status,0))       AS poverty_rate,
    SAFE_DIVIDE(none.births, tot.births)                                     AS pct_no_morbidity
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr` AS c
  JOIN (
        SELECT County_of_Residence_FIPS AS fips, SUM(Births) AS births
        FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
        WHERE Year = '2018-01-01'
        GROUP BY fips)                 AS tot          ON tot.fips  = c.geo_id
  JOIN (
        SELECT County_of_Residence_FIPS AS fips, SUM(Births) AS births
        FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
        WHERE Year = '2018-01-01'
          AND Maternal_Morbidity_Desc = 'None checked'
        GROUP BY fips)                 AS none         ON none.fips = c.geo_id
  WHERE c.poverty IS NOT NULL AND c.pop_determined_poverty_status > 0
)

/* ---------- Correlation per year ---------- */
SELECT
  yr                                                         AS year,
  CORR(poverty_rate, pct_no_morbidity)                       AS pearson_correlation
FROM (
  SELECT * FROM year_2016
  UNION ALL
  SELECT * FROM year_2017
  UNION ALL
  SELECT * FROM year_2018
)
GROUP BY yr
ORDER BY yr;
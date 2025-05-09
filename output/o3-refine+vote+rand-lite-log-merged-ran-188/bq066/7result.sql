/*  Poverty (prior-year 5-yr ACS) vs. share of births with NO maternal morbidity
    for natality years 2016-2018                                             */

WITH
/* ---------- 2016 births paired with 2015-vintage poverty ----------------- */
c16 AS (
  WITH pov AS (
    SELECT
      CAST(`geo_id` AS STRING)                                        AS geo_id,
      SAFE_DIVIDE(`poverty`, `total_pop`)                             AS poverty_rate
    FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
    WHERE `poverty` IS NOT NULL AND `total_pop` IS NOT NULL
  ),
  births AS (
    SELECT
      CAST(`County_of_Residence_FIPS` AS STRING)                      AS geo_id,
      SAFE_DIVIDE(
        SUM(IF(`Maternal_Morbidity_Desc` = 'None checked', `Births`, 0)),
        SUM(`Births`)
      )                                                               AS pct_no_morbidity
    FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE EXTRACT(YEAR FROM `Year`) = 2016
    GROUP BY geo_id
  )
  SELECT '2016' AS yr,
         CORR(poverty_rate, pct_no_morbidity)                         AS corr
  FROM pov
  JOIN births USING (geo_id)
),

/* ---------- 2017 births paired with 2016-vintage poverty ----------------- */
c17 AS (
  WITH pov AS (
    SELECT
      CAST(`geo_id` AS STRING)                                        AS geo_id,
      SAFE_DIVIDE(`poverty`, `total_pop`)                             AS poverty_rate
    FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
    WHERE `poverty` IS NOT NULL AND `total_pop` IS NOT NULL
  ),
  births AS (
    SELECT
      CAST(`County_of_Residence_FIPS` AS STRING)                      AS geo_id,
      SAFE_DIVIDE(
        SUM(IF(`Maternal_Morbidity_Desc` = 'None checked', `Births`, 0)),
        SUM(`Births`)
      )                                                               AS pct_no_morbidity
    FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE EXTRACT(YEAR FROM `Year`) = 2017
    GROUP BY geo_id
  )
  SELECT '2017' AS yr,
         CORR(poverty_rate, pct_no_morbidity)                         AS corr
  FROM pov
  JOIN births USING (geo_id)
),

/* ---------- 2018 births paired with 2017-vintage poverty ----------------- */
c18 AS (
  WITH pov AS (
    SELECT
      CAST(`geo_id` AS STRING)                                        AS geo_id,
      SAFE_DIVIDE(`poverty`, `total_pop`)                             AS poverty_rate
    FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
    WHERE `poverty` IS NOT NULL AND `total_pop` IS NOT NULL
  ),
  births AS (
    SELECT
      CAST(`County_of_Residence_FIPS` AS STRING)                      AS geo_id,
      SAFE_DIVIDE(
        SUM(IF(`Maternal_Morbidity_Desc` = 'None checked', `Births`, 0)),
        SUM(`Births`)
      )                                                               AS pct_no_morbidity
    FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
    WHERE EXTRACT(YEAR FROM `Year`) = 2018
    GROUP BY geo_id
  )
  SELECT '2018' AS yr,
         CORR(poverty_rate, pct_no_morbidity)                         AS corr
  FROM pov
  JOIN births USING (geo_id)
)

/* ----------------------------- Results ----------------------------------- */
SELECT * FROM c16
UNION ALL
SELECT * FROM c17
UNION ALL
SELECT * FROM c18;
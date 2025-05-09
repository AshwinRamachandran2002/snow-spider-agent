WITH
-- births with NO maternal morbidity
maternal AS (
  SELECT
    EXTRACT(YEAR FROM Year)         AS birth_year,
    County_of_Residence_FIPS        AS fips,
    SUM(Births)                     AS births_no_morbidity            -- “None checked”
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE
    Maternal_Morbidity_Desc = 'None checked'
    AND EXTRACT(YEAR FROM Year) IN (2016, 2017, 2018)
  GROUP BY birth_year, fips
),
-- total births
total_births AS (
  SELECT
    EXTRACT(YEAR FROM Year)         AS birth_year,
    County_of_Residence_FIPS        AS fips,
    SUM(Births)                     AS total_births
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) IN (2016, 2017, 2018)
  GROUP BY birth_year, fips
),
-- percentage of births with NO maternal morbidity
pct_no_morbidity AS (
  SELECT
    t.birth_year,
    t.fips,
    SAFE_DIVIDE(m.births_no_morbidity, t.total_births) * 100 AS pct_no_morbidity
  FROM total_births t
  JOIN maternal m
  USING (birth_year, fips)
),
-- poverty rates from PRIOR‑YEAR 5‑yr ACS
poverty AS (
  SELECT '2016' AS birth_year, geo_id AS fips,
         SAFE_DIVIDE(poverty, pop_determined_poverty_status) * 100 AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  SELECT '2017',   geo_id, SAFE_DIVIDE(poverty, pop_determined_poverty_status) * 100
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  SELECT '2018',   geo_id, SAFE_DIVIDE(poverty, pop_determined_poverty_status) * 100
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
-- combine births & poverty info
joined AS (
  SELECT
    p.birth_year,
    p.fips,
    p.poverty_rate,
    n.pct_no_morbidity
  FROM pct_no_morbidity  n
  JOIN poverty           p
  ON  p.birth_year = CAST(n.birth_year AS STRING)
  AND p.fips       = n.fips
  WHERE p.poverty_rate IS NOT NULL
        AND n.pct_no_morbidity IS NOT NULL
)
-- Pearson correlation per year
SELECT
  birth_year                                           AS year,
  CORR(poverty_rate, pct_no_morbidity)                 AS pearson_correlation
FROM joined
GROUP BY birth_year
ORDER BY year;
WITH births_no_morb AS (
  SELECT
    EXTRACT(YEAR FROM Year) AS birth_year,
    County_of_Residence_FIPS           AS fips,
    SUM(Births)                        AS births_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE Maternal_Morbidity_Desc = 'None checked'
    AND EXTRACT(YEAR FROM Year) IN (2016, 2017, 2018)
  GROUP BY birth_year, fips
),
total_births AS (
  SELECT
    EXTRACT(YEAR FROM Year) AS birth_year,
    County_of_Residence_FIPS AS fips,
    SUM(Births)              AS total_births
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) IN (2016, 2017, 2018)
  GROUP BY birth_year, fips
),
pct_no_morbidity AS (
  SELECT
    t.birth_year,
    t.fips,
    SAFE_DIVIDE(b.births_no_morbidity, t.total_births) AS pct_no_morbidity
  FROM total_births t
  JOIN births_no_morb b
    USING (birth_year, fips)
  WHERE t.total_births > 0
),
poverty_rates AS (
  SELECT
    2016 AS birth_year,
    geo_id                                         AS fips,
    SAFE_DIVIDE(CAST(poverty AS FLOAT64),
                CAST(pop_determined_poverty_status AS FLOAT64)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  WHERE pop_determined_poverty_status > 0

  UNION ALL
  SELECT
    2017,
    geo_id,
    SAFE_DIVIDE(CAST(poverty AS FLOAT64),
                CAST(pop_determined_poverty_status AS FLOAT64))
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  WHERE pop_determined_poverty_status > 0

  UNION ALL
  SELECT
    2018,
    geo_id,
    SAFE_DIVIDE(CAST(poverty AS FLOAT64),
                CAST(pop_determined_poverty_status AS FLOAT64))
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
  WHERE pop_determined_poverty_status > 0
),
combined AS (
  SELECT
    p.birth_year AS year,
    p.fips,
    p.poverty_rate,
    m.pct_no_morbidity
  FROM poverty_rates p
  JOIN pct_no_morbidity m
    ON m.birth_year = p.birth_year
   AND m.fips       = p.fips
  WHERE p.poverty_rate       IS NOT NULL
    AND m.pct_no_morbidity   IS NOT NULL
)
SELECT
  year,
  COUNT(*)                                   AS counties_included,
  CORR(poverty_rate, pct_no_morbidity)       AS pearson_correlation
FROM combined
GROUP BY year
ORDER BY year;
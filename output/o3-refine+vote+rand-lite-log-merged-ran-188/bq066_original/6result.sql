WITH poverty AS (
  -- previous–year 5‑yr ACS poverty rates
  SELECT
    2016 AS year,                          -- 2015 5‑yr ACS used for 2016 births
    geo_id        AS fips,
    SAFE_DIVIDE(CAST(poverty AS FLOAT64),
                CAST(pop_determined_poverty_status AS FLOAT64)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  
  UNION ALL
  SELECT
    2017 AS year,
    geo_id,
    SAFE_DIVIDE(CAST(poverty AS FLOAT64),
                CAST(pop_determined_poverty_status AS FLOAT64)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  
  UNION ALL
  SELECT
    2018 AS year,
    geo_id,
    SAFE_DIVIDE(CAST(poverty AS FLOAT64),
                CAST(pop_determined_poverty_status AS FLOAT64)) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),

births AS (
  -- births where NO maternal morbidity was reported
  SELECT
    EXTRACT(YEAR FROM nm.Year)                    AS year,
    nm.County_of_Residence_FIPS                   AS fips,
    SUM(CASE WHEN mm.Maternal_Morbidity_YN = 1
             THEN mm.Births ELSE 0 END)           AS births_without_morbidity,
    SUM(nm.Births)                                AS total_births
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`                     nm
  LEFT JOIN `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity` mm
         ON nm.Year                     = mm.Year
        AND nm.County_of_Residence_FIPS = mm.County_of_Residence_FIPS
  WHERE EXTRACT(YEAR FROM nm.Year) IN (2016, 2017, 2018)
  GROUP BY year, fips
),

combined AS (
  SELECT
    b.year,
    b.fips,
    SAFE_DIVIDE(b.births_without_morbidity, b.total_births) AS pct_without_morbidity,
    p.poverty_rate
  FROM births  b
  JOIN poverty p
    ON p.year = b.year
   AND p.fips = b.fips
  WHERE b.total_births > 0
)

-- Pearson correlation between county‑level poverty and share of births without maternal morbidity
SELECT
  year,
  CORR(poverty_rate, pct_without_morbidity) AS poverty_vs_no_morbidity_corr
FROM combined
GROUP BY year
ORDER BY year;
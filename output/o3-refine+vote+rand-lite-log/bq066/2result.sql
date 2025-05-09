WITH poverty AS (
  -- Poverty rate from the ACS 5–year file of the PREVIOUS year
  SELECT
    LPAD(SUBSTR(geo_id, 1, 5),5,'0')                    AS fips,
    2015                                                AS acs_year,      -- will pair with natality 2016
    SAFE_DIVIDE(CAST(poverty AS NUMERIC),
                NULLIF(CAST(pop_determined_poverty_status AS NUMERIC),0))
                AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`

  UNION ALL
  SELECT
    LPAD(SUBSTR(geo_id, 1, 5),5,'0') ,
    2016,
    SAFE_DIVIDE(CAST(poverty AS NUMERIC),
                NULLIF(CAST(pop_determined_poverty_status AS NUMERIC),0))
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`

  UNION ALL
  SELECT
    LPAD(SUBSTR(geo_id, 1, 5),5,'0') ,
    2017,
    SAFE_DIVIDE(CAST(poverty AS NUMERIC),
                NULLIF(CAST(pop_determined_poverty_status AS NUMERIC),0))
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
-- births with NO maternal morbidity
no_morbidity AS (
  SELECT
    EXTRACT(YEAR FROM Year)             AS yr,
    LPAD(County_of_Residence_FIPS,5,'0') AS fips,
    SUM(Births)                         AS births_no_morb
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE Maternal_Morbidity_Desc = 'None checked'
    AND EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY yr, fips
),
-- total births
all_births AS (
  SELECT
    EXTRACT(YEAR FROM Year)             AS yr,
    LPAD(County_of_Residence_FIPS,5,'0') AS fips,
    SUM(Births)                         AS births_total
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY yr, fips
),
-- percentage of births with no maternal morbidity
birth_rates AS (
  SELECT
    n.yr,
    n.fips,
    SAFE_DIVIDE(n.births_no_morb, a.births_total) * 100 AS pct_no_morbidity
  FROM no_morbidity n
  JOIN all_births  a USING (yr, fips)
  WHERE a.births_total > 0
),
-- combine with poverty of previous year
join_poverty AS (
  SELECT
    b.yr,
    b.fips,
    b.pct_no_morbidity,
    p.poverty_rate
  FROM birth_rates b
  LEFT JOIN poverty p
          ON p.fips = b.fips
         AND p.acs_year = b.yr - 1     -- use previous‑year ACS
  WHERE p.poverty_rate IS NOT NULL
)
-- compute Pearson correlation for each year
SELECT
  yr  AS birth_year,
  CORR(poverty_rate, pct_no_morbidity) AS poverty_vs_no_morbidity_corr
FROM join_poverty
GROUP BY yr
ORDER BY yr;
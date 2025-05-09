/* ------------------------------------------------------------
   Relationship between county-level poverty (previous-year 5-yr ACS)
   and the share of births WITHOUT maternal morbidity, 2016-2018
   ------------------------------------------------------------ */
WITH births AS (
  /* 1.  County-level counts of total births and births with NO maternal morbidity */
  SELECT
    EXTRACT(YEAR FROM Year)                    AS birth_year,
    County_of_Residence_FIPS                  AS geo_id,
    SUM(CASE WHEN Maternal_Morbidity_YN = 0
             THEN Births END)                 AS births_no_morbidity,
    SUM(Births)                               AS births_total
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY birth_year, geo_id
),
birth_rates AS (
  /* 2.  Percentage of births with NO maternal morbidity */
  SELECT
    birth_year,
    geo_id,
    SAFE_DIVIDE(births_no_morbidity, births_total) AS pct_no_morbidity
  FROM births
),
poverty AS (
  /* 3.  Poverty rates from the PREVIOUS-YEAR 5-year ACS files */
  SELECT
      2016                                      AS birth_year,   -- will pair to 2016 births
      geo_id,
      SAFE_DIVIDE(poverty, total_pop)           AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  
  UNION ALL
  SELECT
      2017,
      geo_id,
      SAFE_DIVIDE(poverty, total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`

  UNION ALL
  SELECT
      2018,
      geo_id,
      SAFE_DIVIDE(poverty, total_pop)
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
joined AS (
  /* 4.  Pair poverty rates with corresponding birth percentages */
  SELECT
    b.birth_year,
    b.geo_id,
    b.pct_no_morbidity,
    p.poverty_rate
  FROM birth_rates b
  JOIN poverty     p
    ON b.birth_year = p.birth_year
   AND b.geo_id    = p.geo_id
)
-- 5.  Pearson correlation between poverty rate and share of births with NO morbidity
SELECT
  birth_year,
  CORR(poverty_rate, pct_no_morbidity) AS pearson_correlation
FROM joined
GROUP BY birth_year
ORDER BY birth_year;
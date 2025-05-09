/*  Pearson correlation between county-level poverty rates (from the
    prior-year 5-year ACS release) and the share of births with NO
    maternal morbidity for birth cohorts 2016-2018.                    */

WITH poverty AS (
  /* Pull poverty rates from the three ACS county files whose
     releases immediately precede the 2016-2018 birth years.        */
  SELECT
    CAST(REGEXP_EXTRACT(_TABLE_SUFFIX, r'(\d{4})') AS INT64) + 1   AS birth_year,   -- 2015 file → 2016 births, etc.
    geo_id,
    poverty / NULLIF(total_pop,0)                                 AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_*`
  WHERE _TABLE_SUFFIX IN ('2015_5yr','2016_5yr','2017_5yr')
    AND poverty   IS NOT NULL
    AND total_pop IS NOT NULL
    AND total_pop > 0
),
births AS (
  /* Aggregate total births and births WITHOUT maternal morbidity.  */
  SELECT
    EXTRACT(YEAR FROM Year)                    AS birth_year,
    County_of_Residence_FIPS                   AS geo_id,
    SUM(Births)                                AS total_births,
    SUM(CASE WHEN Maternal_Morbidity_YN = 0
             THEN Births END)                 AS births_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY birth_year, geo_id
)

SELECT
  b.birth_year,
  CORR( b.births_no_morbidity / NULLIF(b.total_births,0) ,   -- share of births w/o morbidity
        p.poverty_rate )                         AS pearson_r
FROM births  AS b
JOIN poverty AS p
  ON  p.birth_year = b.birth_year
  AND p.geo_id     = b.geo_id
WHERE b.total_births > 0
GROUP BY b.birth_year
ORDER BY b.birth_year;
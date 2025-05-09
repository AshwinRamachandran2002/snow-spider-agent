/*  Pearson correlation between county-level poverty rates from the
    PREVIOUS year’s 5-year ACS file and the share of births with NO
    maternal morbidity, for birth years 2016-2018.                       */

WITH acs AS (   -- poverty rates from the prior-year ACS 5-year file
  SELECT
    CAST(REGEXP_EXTRACT(_TABLE_SUFFIX, r'(\d{4})') AS INT64) AS acs_year,   -- e.g. 2015
    geo_id                                          AS county_fips,
    SAFE_DIVIDE(poverty , total_pop)               AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_*`
  WHERE _TABLE_SUFFIX IN ('2015_5yr','2016_5yr','2017_5yr')    -- years we need
    AND total_pop IS NOT NULL
),

births AS (   -- % of births with NO maternal morbidity
  SELECT
    EXTRACT(YEAR FROM Year)              AS birth_year,
    County_of_Residence_FIPS             AS county_fips,
    SAFE_DIVIDE(
        SUM(CASE WHEN Maternal_Morbidity_YN = 0 THEN Births END),
        SUM(Births)
    )                                    AS pct_births_no_morbidity
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY birth_year, county_fips
),

joined AS (   -- match each birth year with poverty from the previous year
  SELECT
    b.birth_year,
    a.poverty_rate,
    b.pct_births_no_morbidity
  FROM births b
  JOIN acs   a
    ON a.acs_year    = b.birth_year - 1      -- previous-year ACS
   AND a.county_fips = b.county_fips
)

SELECT
  birth_year,
  CORR(poverty_rate, pct_births_no_morbidity) AS pearson_corr
FROM joined
GROUP BY birth_year
ORDER BY birth_year;
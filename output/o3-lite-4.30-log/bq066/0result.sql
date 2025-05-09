WITH poverty AS (
  -- 2016 births paired with 2015 ACS poverty rates
  SELECT
    2016 AS year,
    geo_id AS fips,
    SAFE_DIVIDE(poverty, total_pop) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2015_5yr`
  UNION ALL
  -- 2017 births paired with 2016 ACS poverty rates
  SELECT
    2017 AS year,
    geo_id AS fips,
    SAFE_DIVIDE(poverty, total_pop) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2016_5yr`
  UNION ALL
  -- 2018 births paired with 2017 ACS poverty rates
  SELECT
    2018 AS year,
    geo_id AS fips,
    SAFE_DIVIDE(poverty, total_pop) AS poverty_rate
  FROM `bigquery-public-data.census_bureau_acs.county_2017_5yr`
),
births_total AS (
  SELECT
    EXTRACT(YEAR FROM Year) AS year,
    County_of_Residence_FIPS AS fips,
    SUM(Births) AS births_total
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
  GROUP BY year, fips
),
births_no_mm AS (
  SELECT
    EXTRACT(YEAR FROM Year) AS year,
    County_of_Residence_FIPS AS fips,
    SUM(Births) AS births_no_mm
  FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity`
  WHERE EXTRACT(YEAR FROM Year) BETWEEN 2016 AND 2018
    AND Maternal_Morbidity_Desc = 'None checked'
    AND Maternal_Morbidity_YN = 1
  GROUP BY year, fips
),
combined AS (
  SELECT
    p.year,
    p.fips,
    p.poverty_rate,
    SAFE_DIVIDE(n.births_no_mm, t.births_total) AS pct_no_mm
  FROM poverty p
  JOIN births_total t USING (year, fips)
  JOIN births_no_mm n USING (year, fips)
)
SELECT
  CAST(year AS INT64) AS year,
  ROUND(CORR(poverty_rate, pct_no_mm), 4) AS poverty_vs_no_morbidity_pearson_r
FROM combined
GROUP BY year
ORDER BY year;
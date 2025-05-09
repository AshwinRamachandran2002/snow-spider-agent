-- Utah county with the greatest % increase in construction employment (2000→2018)
WITH construction_qcew AS (
  /* Month‑3 construction employment for the four quarters of 2000 and 2018 */
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64) AS year,
    area_fips,                                -- 5‑digit county FIPS
    month3_emplvl_23_construction             AS emp
  FROM `bigquery-public-data.bls_qcew.*`
  WHERE _TABLE_SUFFIX IN ('2000_q1','2000_q2','2000_q3','2000_q4',
                          '2018_q1','2018_q2','2018_q3','2018_q4')
),
avg_year AS (
  /* Average the four quarter‑3‑month values within each year */
  SELECT
    area_fips,
    year,
    AVG(emp) AS avg_emp
  FROM construction_qcew
  GROUP BY area_fips, year
),
utah_counties AS (
  /* Utah counties and names */
  SELECT
    geo_id        AS area_fips,
    county_name
  FROM `bigquery-public-data.geo_us_boundaries.counties`
  WHERE state_fips_code = '49'   -- Utah
),
yr_pivot AS (
  /* Put 2000 and 2018 averages side‑by‑side */
  SELECT
    u.county_name,
    MAX(CASE WHEN a.year = 2000 THEN a.avg_emp END) AS emp_2000,
    MAX(CASE WHEN a.year = 2018 THEN a.avg_emp END) AS emp_2018
  FROM avg_year a
  JOIN utah_counties u USING (area_fips)
  GROUP BY u.county_name
),
pct_change AS (
  SELECT
    county_name,
    ((emp_2018 - emp_2000) / emp_2000) * 100 AS pct_increase
  FROM yr_pivot
  WHERE emp_2000 IS NOT NULL
    AND emp_2018 IS NOT NULL
    AND emp_2000 > 0
)
SELECT
  county_name,
  pct_increase
FROM pct_change
ORDER BY pct_increase DESC
LIMIT 1;
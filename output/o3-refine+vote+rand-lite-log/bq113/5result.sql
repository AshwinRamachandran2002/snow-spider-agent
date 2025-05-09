-- 1.  Collect the average 3rd–month‑of‑quarter construction employment
--    for each Utah county in 2000 and in 2018.
WITH yearly_avg AS (
  SELECT
      area_fips,                                             -- county FIPS
      CASE                                                    -- derive year from table name
        WHEN _TABLE_SUFFIX LIKE '2000_%' THEN 2000
        WHEN _TABLE_SUFFIX LIKE '2018_%' THEN 2018
      END AS yr,
      AVG(month3_emplvl_23_construction) AS avg_empl          -- average of the four quarters
  FROM
      `bigquery-public-data.bls_qcew.*`
  WHERE
      _TABLE_SUFFIX IN ('2000_q1','2000_q2','2000_q3','2000_q4',
                        '2018_q1','2018_q2','2018_q3','2018_q4')
      AND area_fips LIKE '49%'        -- Utah (state FIPS 49)
      AND LENGTH(area_fips) = 5       -- keep counties (5‑digit FIPS)
  GROUP BY
      area_fips, yr
),

-- 2.  Pivot the two years side‑by‑side.
pivot AS (
  SELECT
      area_fips,
      MAX(CASE WHEN yr = 2000 THEN avg_empl END) AS avg_2000,
      MAX(CASE WHEN yr = 2018 THEN avg_empl END) AS avg_2018
  FROM yearly_avg
  GROUP BY area_fips
),

-- 3.  Calculate percent change.
growth AS (
  SELECT
      area_fips,
      avg_2000,
      avg_2018,
      (avg_2018 - avg_2000) / avg_2000 * 100 AS pct_increase
  FROM pivot
  WHERE avg_2000 IS NOT NULL AND avg_2018 IS NOT NULL
),

-- 4.  Pick the county with the greatest increase.
max_growth AS (
  SELECT *
  FROM growth
  ORDER BY pct_increase DESC
  LIMIT 1
)

-- 5.  Attach county name and show the result.
SELECT
    c.county_name  AS utah_county,
    ROUND(mg.pct_increase, 2) AS percentage_increase
FROM max_growth mg
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.county_fips_code = mg.area_fips;
/*  Top three races with the largest %‑point gap between Google 2021 overall‑hiring
    and the 2021 BLS averages for the four specified “tech” industries            */

WITH
/* ---------- 1.  Google overall hiring, 2021 ---------- */
google_2021 AS (
  SELECT
    race_asian ,
    race_black ,
    race_hispanic_latinx ,
    race_white
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
        AND workforce   = 'overall'
  LIMIT 1             -- keep exactly one row
),

/* ---------- 2.  BLS 2021 tech‑sector averages ---------- */
bls_tech_2021 AS (
  SELECT
    AVG(percent_asian)                   AS race_asian ,
    AVG(percent_black_or_african_american) AS race_black ,
    AVG(percent_hispanic_or_latino)      AS race_hispanic_latinx ,
    AVG(percent_white)                   AS race_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          LOWER(industry)       IN ('internet publishing and broadcasting and web search portals',
                                    'software publishers',
                                    'data processing, hosting, and related services',
                                    'computer systems design and related services')
       OR LOWER(industry_group) IN ('internet publishing and broadcasting and web search portals',
                                    'software publishers',
                                    'data processing, hosting, and related services',
                                    'computer systems design and related services')
        )
),

/* ---------- 3.  Absolute differences (Google – BLS) ---------- */
diffs AS (
  SELECT 'Asian'              AS race , ABS(g.race_asian            - b.race_asian)            AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b UNION ALL
  SELECT 'Black'              AS race , ABS(g.race_black            - b.race_black)            AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b UNION ALL
  SELECT 'Hispanic or Latinx' AS race , ABS(g.race_hispanic_latinx  - b.race_hispanic_latinx)  AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b UNION ALL
  SELECT 'White'              AS race , ABS(g.race_white            - b.race_white)            AS diff FROM google_2021 g CROSS JOIN bls_tech_2021 b
)

/* ---------- 4.  Return top‑3 races ---------- */
SELECT race,
       diff
FROM   diffs
ORDER  BY diff DESC
LIMIT  3;
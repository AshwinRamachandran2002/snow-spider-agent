-- Top three races with the largest percentage‐point gaps between
-- Google’s 2021 overall U.S. hiring and 2021 BLS averages for key tech industries
WITH google_2021 AS (
  SELECT
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce = 'overall'
  LIMIT 1
),
bls_tech_2021 AS (
  SELECT
    AVG(percent_asian)  AS race_asian,
    AVG(percent_black_or_african_american) AS race_black,
    AVG(percent_hispanic_or_latino) AS race_hispanic_latinx,
    AVG(percent_white)  AS race_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
      LOWER(industry)       LIKE '%internet publishing%'
      OR LOWER(industry)    LIKE '%software publisher%'
      OR LOWER(industry)    LIKE '%data processing%'
      OR LOWER(industry)    LIKE '%computer systems design%'
      OR LOWER(industry_group) LIKE '%computer systems design%'
    )
),
diffs AS (
  SELECT 'Asian'           AS race,
         ABS(g.race_asian           - b.race_asian)           AS pct_point_gap
  FROM google_2021 g CROSS JOIN bls_tech_2021 b
  UNION ALL
  SELECT 'Black',          ABS(g.race_black          - b.race_black)
  FROM google_2021 g CROSS JOIN bls_tech_2021 b
  UNION ALL
  SELECT 'Hispanic/Latinx',ABS(g.race_hispanic_latinx- b.race_hispanic_latinx)
  FROM google_2021 g CROSS JOIN bls_tech_2021 b
  UNION ALL
  SELECT 'White',          ABS(g.race_white          - b.race_white)
  FROM google_2021 g CROSS JOIN bls_tech_2021 b
)
SELECT race,
       ROUND(pct_point_gap,4) AS pct_point_gap
FROM diffs
ORDER BY pct_point_gap DESC
LIMIT 3;
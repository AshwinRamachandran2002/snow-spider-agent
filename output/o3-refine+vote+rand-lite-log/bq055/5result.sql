-- Top three races with the largest 2021 hiring‑share gaps
WITH google AS (
  SELECT
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls AS (
  SELECT
    AVG(percent_asian)                       AS bls_asian,
    AVG(percent_black_or_african_american)   AS bls_black,
    AVG(percent_hispanic_or_latino)          AS bls_hispanic_latinx,
    AVG(percent_white)                       AS bls_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         industry       = 'Internet publishing and broadcasting and web search portals'
      OR industry       = 'Software publishers'
      OR industry       = 'Data processing, hosting, and related services'
      OR industry_group = 'Computer systems design and related services'
    )
),
diffs AS (
  SELECT 'Asian'              AS race, ABS(g.race_asian          - b.bls_asian         ) * 100 AS diff_pct
  FROM   google g CROSS JOIN bls b
  UNION ALL
  SELECT 'Black'              AS race, ABS(g.race_black          - b.bls_black         ) * 100
  FROM   google g CROSS JOIN bls b
  UNION ALL
  SELECT 'Hispanic or Latinx' AS race, ABS(g.race_hispanic_latinx- b.bls_hispanic_latinx) * 100
  FROM   google g CROSS JOIN bls b
  UNION ALL
  SELECT 'White'              AS race, ABS(g.race_white          - b.bls_white         ) * 100
  FROM   google g CROSS JOIN bls b
)
SELECT
  race,
  ROUND(diff_pct,4) AS percentage_point_difference
FROM diffs
ORDER BY diff_pct DESC, race
LIMIT 3;
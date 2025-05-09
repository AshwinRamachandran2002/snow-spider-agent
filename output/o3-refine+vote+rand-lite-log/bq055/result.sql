WITH google_hiring_2021 AS (
  SELECT
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce = 'overall'
),
bls_tech_2021 AS (
  SELECT
    percent_white,
    percent_black_or_african_american,
    percent_asian,
    percent_hispanic_or_latino
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         industry IN ('Internet publishing and broadcasting and web search portals',
                      'Software publishers',
                      'Data processing, hosting, and related services')
      OR industry_group IN ('Computer systems design and related services')
    )
),
bls_avg AS (
  SELECT
    AVG(percent_asian)                     AS race_asian,
    AVG(percent_black_or_african_american) AS race_black,
    AVG(percent_hispanic_or_latino)        AS race_hispanic_latinx,
    AVG(percent_white)                     AS race_white
  FROM bls_tech_2021
),
race_differences AS (
  SELECT 'Asian'           AS race, g.race_asian           - b.race_asian           AS diff FROM google_hiring_2021 g CROSS JOIN bls_avg b UNION ALL
  SELECT 'Black'           AS race, g.race_black           - b.race_black           AS diff FROM google_hiring_2021 g CROSS JOIN bls_avg b UNION ALL
  SELECT 'Hispanic/Latinx' AS race, g.race_hispanic_latinx - b.race_hispanic_latinx AS diff FROM google_hiring_2021 g CROSS JOIN bls_avg b UNION ALL
  SELECT 'White'           AS race, g.race_white           - b.race_white           AS diff FROM google_hiring_2021 g CROSS JOIN bls_avg b
)
SELECT
  race,
  diff AS percentage_difference
FROM race_differences
ORDER BY ABS(diff) DESC
LIMIT 3;
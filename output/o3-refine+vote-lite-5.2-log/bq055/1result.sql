WITH google AS (
  -- 1. 2021 Google hiring percentages (overall workforce)
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
  -- 2. 2021 BLS weighted‑average race shares for the four technology industries
  SELECT
    SUM(total_employed_in_thousands * percent_asian)   / SUM(total_employed_in_thousands) AS bls_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american) / SUM(total_employed_in_thousands) AS bls_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino)        / SUM(total_employed_in_thousands) AS bls_hispanic_latinx,
    SUM(total_employed_in_thousands * percent_white)   / SUM(total_employed_in_thousands) AS bls_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
          'Internet publishing and broadcasting and web search portals',
          'Software publishers',
          'Data processing, hosting, and related services',
          'Computer systems design and related services'
        )
),
diffs AS (
  -- 3. Differences (Google – BLS) for each race
  SELECT 'Asian'           AS race, g.race_asian           - b.bls_asian           AS diff FROM google g CROSS JOIN bls b UNION ALL
  SELECT 'Black'           AS race, g.race_black           - b.bls_black           AS diff FROM google g CROSS JOIN bls b UNION ALL
  SELECT 'Hispanic/Latinx' AS race, g.race_hispanic_latinx - b.bls_hispanic_latinx AS diff FROM google g CROSS JOIN bls b UNION ALL
  SELECT 'White'           AS race, g.race_white           - b.bls_white           AS diff FROM google g CROSS JOIN bls b
)
-- 4. Top three races by absolute percentage difference
SELECT
  race,
  ROUND(diff, 4)      AS percentage_difference,
  ROUND(ABS(diff),4)  AS absolute_difference
FROM diffs
ORDER BY absolute_difference DESC
LIMIT 3;
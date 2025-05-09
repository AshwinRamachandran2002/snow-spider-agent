WITH google AS (
  -- Google 2021 overall hiring percentages
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
  -- 2021 BLS averages for the specified technology industries
  SELECT
    AVG(percent_asian)                     AS race_asian,
    AVG(percent_black_or_african_american) AS race_black,
    AVG(percent_hispanic_or_latino)        AS race_hispanic_latinx,
    AVG(percent_white)                     AS race_white
  FROM `bigquery-public-data.google_dei.full_csv-latest-data-is-2023`
  WHERE year = 2021
    AND (
         industry = 'Internet publishing and broadcasting and web search portals'
      OR industry = 'Software publishers'
      OR industry = 'Data processing, hosting, and related services'
      OR industry_group = 'Computer systems design and related services'
    )
),
combined AS (
  -- Turn the data into a long (race‑by‑race) format
  SELECT 'Asian'                     AS race, g.race_asian           AS google_pct, b.race_asian           AS bls_pct FROM google g CROSS JOIN bls b UNION ALL
  SELECT 'Black or African American' AS race, g.race_black           AS google_pct, b.race_black           AS bls_pct FROM google g CROSS JOIN bls b UNION ALL
  SELECT 'Hispanic or Latino'        AS race, g.race_hispanic_latinx AS google_pct, b.race_hispanic_latinx AS bls_pct FROM google g CROSS JOIN bls b UNION ALL
  SELECT 'White'                     AS race, g.race_white           AS google_pct, b.race_white           AS bls_pct FROM google g CROSS JOIN bls b
),
diffs AS (
  -- Calculate signed and absolute differences
  SELECT
    race,
    ROUND(google_pct - bls_pct, 4)       AS difference,
    ABS(google_pct - bls_pct)            AS abs_difference
  FROM combined
)
-- Return the three races with the largest absolute differences
SELECT
  race,
  difference
FROM diffs
ORDER BY abs_difference DESC, race
LIMIT 3;
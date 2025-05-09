WITH google_hiring AS (
  SELECT
    'Asian' AS race,
    race_asian AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'tech'

  UNION ALL

  SELECT
    'Black' AS race,
    race_black AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'tech'

  UNION ALL

  SELECT
    'Hispanic/Latinx' AS race,
    race_hispanic_latinx AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'tech'
),
bls_averages AS (
  SELECT
    'Asian' AS race,
    AVG(percent_asian) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE
    year = 2021 AND industry_group IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services',
      'Computer systems design and related services'
    )

  UNION ALL

  SELECT
    'Black' AS race,
    AVG(percent_black_or_african_american) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE
    year = 2021 AND industry_group IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services',
      'Computer systems design and related services'
    )

  UNION ALL

  SELECT
    'Hispanic/Latinx' AS race,
    AVG(percent_hispanic_or_latino) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE
    year = 2021 AND industry_group IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services',
      'Computer systems design and related services'
    )
),
differences AS (
  SELECT
    g.race,
    g.google_percentage,
    b.bls_percentage,
    g.google_percentage - b.bls_percentage AS percentage_difference
  FROM google_hiring g
  JOIN bls_averages b ON g.race = b.race
)
SELECT
  race,
  ROUND(percentage_difference, 4) AS percentage_difference
FROM differences
ORDER BY ABS(percentage_difference) DESC
LIMIT 3;
WITH google_data AS (
  SELECT
    'Asian' AS Race,
    race_asian AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'overall'
  UNION ALL
  SELECT
    'Black' AS Race,
    race_black AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'overall'
  UNION ALL
  SELECT
    'Hispanic or Latinx' AS Race,
    race_hispanic_latinx AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'overall'
  UNION ALL
  SELECT
    'White' AS Race,
    race_white AS google_percentage
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND LOWER(workforce) = 'overall'
),
bls_data AS (
  SELECT
    'Asian' AS Race,
    AVG(percent_asian) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND (
    industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR industry_group = 'Computer systems design and related services'
  )
  UNION ALL
  SELECT
    'Black' AS Race,
    AVG(percent_black_or_african_american) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND (
    industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR industry_group = 'Computer systems design and related services'
  )
  UNION ALL
  SELECT
    'Hispanic or Latinx' AS Race,
    AVG(percent_hispanic_or_latino) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND (
    industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR industry_group = 'Computer systems design and related services'
  )
  UNION ALL
  SELECT
    'White' AS Race,
    AVG(percent_white) AS bls_percentage
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021 AND (
    industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Software publishers',
      'Data processing, hosting, and related services'
    ) OR industry_group = 'Computer systems design and related services'
  )
)
SELECT
  g.Race,
  ROUND((g.google_percentage - b.bls_percentage) * 100, 4) AS Difference
FROM google_data g
JOIN bls_data b ON g.Race = b.Race
ORDER BY ABS(Difference) DESC
LIMIT 3;
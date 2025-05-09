WITH google_hiring AS (
  SELECT
    race_asian,
    race_black,
    race_hispanic_latinx
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
),
bls_averages AS (
  SELECT
    SUM(percent_asian * total_employed_in_thousands) / SUM(total_employed_in_thousands) AS bls_percent_asian,
    SUM(percent_black_or_african_american * total_employed_in_thousands) / SUM(total_employed_in_thousands) AS bls_percent_black,
    SUM(percent_hispanic_or_latino * total_employed_in_thousands) / SUM(total_employed_in_thousands) AS bls_percent_hispanic_latinx
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE
    year = 2021
    AND (
      LOWER(industry) LIKE '%software publishers%'
      OR LOWER(industry) LIKE '%data processing, hosting%'
      OR LOWER(industry) LIKE '%internet publishing and broadcasting%'
      OR LOWER(industry_group) = 'computer systems design and related services'
    )
)
SELECT
  Race,
  ROUND(Percentage_Difference, 4) AS Percentage_Difference
FROM (
  SELECT
    'Asian' AS Race,
    (google_hiring.race_asian - bls_averages.bls_percent_asian) AS Percentage_Difference
  FROM google_hiring CROSS JOIN bls_averages
  UNION ALL
  SELECT
    'Black' AS Race,
    (google_hiring.race_black - bls_averages.bls_percent_black) AS Percentage_Difference
  FROM google_hiring CROSS JOIN bls_averages
  UNION ALL
  SELECT
    'Hispanic/Latinx' AS Race,
    (google_hiring.race_hispanic_latinx - bls_averages.bls_percent_hispanic_latinx) AS Percentage_Difference
  FROM google_hiring CROSS JOIN bls_averages
)
ORDER BY ABS(Percentage_Difference) DESC
LIMIT 3
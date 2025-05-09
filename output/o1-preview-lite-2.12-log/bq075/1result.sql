WITH
  hiring AS (
    SELECT
      race_asian,
      race_black,
      race_hispanic_latinx,
      race_white,
      gender_us_women,
      gender_us_men
    FROM
      `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
    WHERE
      report_year = 2021
      AND LOWER(workforce) = 'overall'
  ),
  representation AS (
    SELECT
      race_asian,
      race_black,
      race_hispanic_latinx,
      race_white,
      gender_us_women,
      gender_us_men
    FROM
      `bigquery-public-data.google_dei.dar_non_intersectional_representation`
    WHERE
      report_year = 2021
      AND LOWER(workforce) = 'overall'
  ),
  bls_data AS (
    SELECT
      percent_women,
      percent_white,
      percent_black_or_african_american,
      percent_asian,
      percent_hispanic_or_latino,
      1.0 - percent_women AS percent_men
    FROM
      `bigquery-public-data.bls.cpsaat18`
    WHERE
      year = 2021
      AND industry = 'Computer and peripheral equipment manufacturing'
  )
SELECT
  'Asian' AS `Group`,
  ROUND(hiring.race_asian * 100, 4) AS Workforce_Hiring_Percentage,
  ROUND(representation.race_asian * 100, 4) AS Workforce_Representation_Percentage,
  ROUND(bls_data.percent_asian * 100, 4) AS BLS_Percentage
FROM
  hiring
  CROSS JOIN representation
  CROSS JOIN bls_data
UNION ALL
SELECT
  'Black' AS `Group`,
  ROUND(hiring.race_black * 100, 4),
  ROUND(representation.race_black * 100, 4),
  ROUND(bls_data.percent_black_or_african_american * 100, 4)
FROM
  hiring
  CROSS JOIN representation
  CROSS JOIN bls_data
UNION ALL
SELECT
  'Hispanic/Latinx' AS `Group`,
  ROUND(hiring.race_hispanic_latinx * 100, 4),
  ROUND(representation.race_hispanic_latinx * 100, 4),
  ROUND(bls_data.percent_hispanic_or_latino * 100, 4)
FROM
  hiring
  CROSS JOIN representation
  CROSS JOIN bls_data
UNION ALL
SELECT
  'White' AS `Group`,
  ROUND(hiring.race_white * 100, 4),
  ROUND(representation.race_white * 100, 4),
  ROUND(bls_data.percent_white * 100, 4)
FROM
  hiring
  CROSS JOIN representation
  CROSS JOIN bls_data
UNION ALL
SELECT
  'U.S. Women' AS `Group`,
  ROUND(hiring.gender_us_women * 100, 4),
  ROUND(representation.gender_us_women * 100, 4),
  ROUND(bls_data.percent_women * 100, 4)
FROM
  hiring
  CROSS JOIN representation
  CROSS JOIN bls_data
UNION ALL
SELECT
  'U.S. Men' AS `Group`,
  ROUND(hiring.gender_us_men * 100, 4),
  ROUND(representation.gender_us_men * 100, 4),
  ROUND(bls_data.percent_men * 100, 4)
FROM
  hiring
  CROSS JOIN representation
  CROSS JOIN bls_data;
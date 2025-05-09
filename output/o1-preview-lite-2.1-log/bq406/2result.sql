WITH data AS (
  SELECT
    report_year,
    'Asian' AS Demographic,
    race_asian AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'Black' AS Demographic,
    race_black AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'Latinx' AS Demographic,
    race_hispanic_latinx AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'Native American' AS Demographic,
    race_native_american AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'White' AS Demographic,
    race_white AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'US women' AS Demographic,
    gender_us_women AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'US men' AS Demographic,
    gender_us_men AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'Global women' AS Demographic,
    gender_global_women AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)

  UNION ALL

  SELECT
    report_year,
    'Global men' AS Demographic,
    gender_global_men AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE LOWER(workforce) = 'overall' AND report_year IN (2014, 2022)
)

SELECT
  Demographic,
  ROUND(((Value_2022 - Value_2014) / Value_2014) * 100, 4) AS Growth_Rate
FROM (
  SELECT
    Demographic,
    MAX(CASE WHEN report_year = 2014 THEN Value END) AS Value_2014,
    MAX(CASE WHEN report_year = 2022 THEN Value END) AS Value_2022
  FROM data
  GROUP BY Demographic
)
ORDER BY Demographic;
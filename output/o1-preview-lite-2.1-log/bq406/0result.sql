WITH data AS (
  SELECT
    report_year,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_native_american,
    race_white,
    gender_us_women,
    gender_us_men,
    gender_global_women,
    gender_global_men
  FROM
    `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE
    workforce = 'overall'
    AND report_year IN (2014, 2022)
),
data_pivot AS (
  SELECT
    'Asian' AS Demographic,
    MAX(CASE WHEN report_year = 2014 THEN race_asian END) AS value_2014,
    MAX(CASE WHEN report_year = 2022 THEN race_asian END) AS value_2022
  FROM data
  UNION ALL
  SELECT
    'Black',
    MAX(CASE WHEN report_year = 2014 THEN race_black END),
    MAX(CASE WHEN report_year = 2022 THEN race_black END)
  FROM data
  UNION ALL
  SELECT
    'Latinx',
    MAX(CASE WHEN report_year = 2014 THEN race_hispanic_latinx END),
    MAX(CASE WHEN report_year = 2022 THEN race_hispanic_latinx END)
  FROM data
  UNION ALL
  SELECT
    'Native American',
    MAX(CASE WHEN report_year = 2014 THEN race_native_american END),
    MAX(CASE WHEN report_year = 2022 THEN race_native_american END)
  FROM data
  UNION ALL
  SELECT
    'White',
    MAX(CASE WHEN report_year = 2014 THEN race_white END),
    MAX(CASE WHEN report_year = 2022 THEN race_white END)
  FROM data
  UNION ALL
  SELECT
    'US Women',
    MAX(CASE WHEN report_year = 2014 THEN gender_us_women END),
    MAX(CASE WHEN report_year = 2022 THEN gender_us_women END)
  FROM data
  UNION ALL
  SELECT
    'US Men',
    MAX(CASE WHEN report_year = 2014 THEN gender_us_men END),
    MAX(CASE WHEN report_year = 2022 THEN gender_us_men END)
  FROM data
  UNION ALL
  SELECT
    'Global Women',
    MAX(CASE WHEN report_year = 2014 THEN gender_global_women END),
    MAX(CASE WHEN report_year = 2022 THEN gender_global_women END)
  FROM data
  UNION ALL
  SELECT
    'Global Men',
    MAX(CASE WHEN report_year = 2014 THEN gender_global_men END),
    MAX(CASE WHEN report_year = 2022 THEN gender_global_men END)
  FROM data
)
SELECT
  Demographic,
  ROUND(((value_2022 - value_2014) / value_2014) * 100, 4) AS Growth_Rate_Percent
FROM
  data_pivot
ORDER BY
  Demographic;
WITH base_year AS (
  SELECT 'Asian' AS Demographic, race_asian AS Value, 1 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'Black' AS Demographic, race_black AS Value, 2 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'Latinx' AS Demographic, race_hispanic_latinx AS Value, 3 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'Native American' AS Demographic, race_native_american AS Value, 4 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'White' AS Demographic, race_white AS Value, 5 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'US women' AS Demographic, gender_us_women AS Value, 6 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'US men' AS Demographic, gender_us_men AS Value, 7 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'Global women' AS Demographic, gender_global_women AS Value, 8 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2014
  UNION ALL
  SELECT 'Global men' AS Demographic, gender_global_men AS Value, 9 AS OrderField
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2014
),
latest_year AS (
  SELECT 'Asian' AS Demographic, race_asian AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'Black' AS Demographic, race_black AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'Latinx' AS Demographic, race_hispanic_latinx AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'Native American' AS Demographic, race_native_american AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'White' AS Demographic, race_white AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'US women' AS Demographic, gender_us_women AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` 
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'US men' AS Demographic, gender_us_men AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'Global women' AS Demographic, gender_global_women AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2022
  UNION ALL
  SELECT 'Global men' AS Demographic, gender_global_men AS Value
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2022
)
SELECT
  base_year.Demographic,
  ROUND(((latest_year.Value - base_year.Value) / base_year.Value) * 100, 4) AS Growth_Rate
FROM base_year
JOIN latest_year USING (Demographic)
ORDER BY base_year.OrderField;
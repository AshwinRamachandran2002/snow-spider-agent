-- Growth rates for race and gender buckets in Google’s overall workforce
-- comparing 2014 (baseline) with 2024 (latest requested year)
WITH base AS (
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
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year IN (2014, 2024)
)
SELECT
  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN race_asian END) -
     MAX(CASE WHEN report_year = 2014 THEN race_asian END))
    / MAX(CASE WHEN report_year = 2014 THEN race_asian END), 4
  ) AS asian_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN race_black END) -
     MAX(CASE WHEN report_year = 2014 THEN race_black END))
    / MAX(CASE WHEN report_year = 2014 THEN race_black END), 4
  ) AS black_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN race_hispanic_latinx END) -
     MAX(CASE WHEN report_year = 2014 THEN race_hispanic_latinx END))
    / MAX(CASE WHEN report_year = 2014 THEN race_hispanic_latinx END), 4
  ) AS latinx_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN race_native_american END) -
     MAX(CASE WHEN report_year = 2014 THEN race_native_american END))
    / MAX(CASE WHEN report_year = 2014 THEN race_native_american END), 4
  ) AS native_american_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN race_white END) -
     MAX(CASE WHEN report_year = 2014 THEN race_white END))
    / MAX(CASE WHEN report_year = 2014 THEN race_white END), 4
  ) AS white_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN gender_us_women END) -
     MAX(CASE WHEN report_year = 2014 THEN gender_us_women END))
    / MAX(CASE WHEN report_year = 2014 THEN gender_us_women END), 4
  ) AS us_women_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN gender_us_men END) -
     MAX(CASE WHEN report_year = 2014 THEN gender_us_men END))
    / MAX(CASE WHEN report_year = 2014 THEN gender_us_men END), 4
  ) AS us_men_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN gender_global_women END) -
     MAX(CASE WHEN report_year = 2014 THEN gender_global_women END))
    / MAX(CASE WHEN report_year = 2014 THEN gender_global_women END), 4
  ) AS global_women_growth,

  ROUND(
    (MAX(CASE WHEN report_year = 2024 THEN gender_global_men END) -
     MAX(CASE WHEN report_year = 2014 THEN gender_global_men END))
    / MAX(CASE WHEN report_year = 2014 THEN gender_global_men END), 4
  ) AS global_men_growth
FROM base;
/* 2014 → 2024 growth rates for the “overall” workforce
   (growth_rate = (value_2024 - value_2014) / value_2014) */

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
),
pivot AS (
  SELECT
    MAX(IF(report_year = 2014, race_asian, NULL))  AS asian_2014,
    MAX(IF(report_year = 2024, race_asian, NULL))  AS asian_2024,
    MAX(IF(report_year = 2014, race_black, NULL))  AS black_2014,
    MAX(IF(report_year = 2024, race_black, NULL))  AS black_2024,
    MAX(IF(report_year = 2014, race_hispanic_latinx, NULL)) AS latinx_2014,
    MAX(IF(report_year = 2024, race_hispanic_latinx, NULL)) AS latinx_2024,
    MAX(IF(report_year = 2014, race_native_american, NULL)) AS native_2014,
    MAX(IF(report_year = 2024, race_native_american, NULL)) AS native_2024,
    MAX(IF(report_year = 2014, race_white, NULL))  AS white_2014,
    MAX(IF(report_year = 2024, race_white, NULL))  AS white_2024,
    MAX(IF(report_year = 2014, gender_us_women, NULL))    AS us_women_2014,
    MAX(IF(report_year = 2024, gender_us_women, NULL))    AS us_women_2024,
    MAX(IF(report_year = 2014, gender_us_men, NULL))      AS us_men_2014,
    MAX(IF(report_year = 2024, gender_us_men, NULL))      AS us_men_2024,
    MAX(IF(report_year = 2014, gender_global_women, NULL)) AS g_women_2014,
    MAX(IF(report_year = 2024, gender_global_women, NULL)) AS g_women_2024,
    MAX(IF(report_year = 2014, gender_global_men, NULL))   AS g_men_2014,
    MAX(IF(report_year = 2024, gender_global_men, NULL))   AS g_men_2024
  FROM base
)
SELECT
  ROUND( (asian_2024  - asian_2014)  / asian_2014 , 4) AS asian_growth_rate,
  ROUND( (black_2024  - black_2014)  / black_2014 , 4) AS black_growth_rate,
  ROUND( (latinx_2024 - latinx_2014) / latinx_2014, 4) AS latinx_growth_rate,
  ROUND( (native_2024 - native_2014) / native_2014, 4) AS native_am_growth_rate,
  ROUND( (white_2024  - white_2014)  / white_2014 , 4) AS white_growth_rate,
  ROUND( (us_women_2024 - us_women_2014) / us_women_2014 , 4) AS us_women_growth_rate,
  ROUND( (us_men_2024   - us_men_2014)  / us_men_2014  , 4) AS us_men_growth_rate,
  ROUND( (g_women_2024  - g_women_2014) / g_women_2014 , 4) AS global_women_growth_rate,
  ROUND( (g_men_2024    - g_men_2014)   / g_men_2014  , 4) AS global_men_growth_rate
FROM pivot;
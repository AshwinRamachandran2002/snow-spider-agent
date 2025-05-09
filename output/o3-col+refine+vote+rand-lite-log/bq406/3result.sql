/*  Growth rates (2014 → 2024) for race and gender shares in Google’s
    overall workforce – non-intersectional representation report            */

WITH base AS (
  SELECT
    MAX(CASE WHEN report_year = 2014 THEN race_asian           END) AS asian_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_asian           END) AS asian_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_black           END) AS black_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_black           END) AS black_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_hispanic_latinx END) AS latinx_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_hispanic_latinx END) AS latinx_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_native_american END) AS native_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_native_american END) AS native_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_white           END) AS white_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_white           END) AS white_2024,

    MAX(CASE WHEN report_year = 2014 THEN gender_us_women      END) AS us_women_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_us_women      END) AS us_women_2024,
    MAX(CASE WHEN report_year = 2014 THEN gender_us_men        END) AS us_men_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_us_men        END) AS us_men_2024,

    MAX(CASE WHEN report_year = 2014 THEN gender_global_women  END) AS g_women_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_global_women  END) AS g_women_2024,
    MAX(CASE WHEN report_year = 2014 THEN gender_global_men    END) AS g_men_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_global_men    END) AS g_men_2024
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year IN (2014, 2024)
)

SELECT
  ROUND(100 * (asian_2024  - asian_2014 ) / asian_2014 , 2) AS asian_growth_pct,
  ROUND(100 * (black_2024  - black_2014 ) / black_2014 , 2) AS black_growth_pct,
  ROUND(100 * (latinx_2024 - latinx_2014) / latinx_2014, 2) AS latinx_growth_pct,
  ROUND(100 * (native_2024 - native_2014) / native_2014, 2) AS native_growth_pct,
  ROUND(100 * (white_2024  - white_2014 ) / white_2014 , 2) AS white_growth_pct,
  ROUND(100 * (us_women_2024 - us_women_2014) / us_women_2014, 2) AS us_women_growth_pct,
  ROUND(100 * (us_men_2024   - us_men_2014 ) / us_men_2014 , 2) AS us_men_growth_pct,
  ROUND(100 * (g_women_2024  - g_women_2014) / g_women_2014, 2) AS global_women_growth_pct,
  ROUND(100 * (g_men_2024    - g_men_2014 ) / g_men_2014  , 2) AS global_men_growth_pct
FROM base;
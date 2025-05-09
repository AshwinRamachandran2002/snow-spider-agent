WITH base AS (
  SELECT
    MAX(IF(report_year = 2014, race_asian,          NULL)) AS asian_2014,
    MAX(IF(report_year = 2024, race_asian,          NULL)) AS asian_2024,
    MAX(IF(report_year = 2014, race_black,          NULL)) AS black_2014,
    MAX(IF(report_year = 2024, race_black,          NULL)) AS black_2024,
    MAX(IF(report_year = 2014, race_hispanic_latinx,NULL)) AS latinx_2014,
    MAX(IF(report_year = 2024, race_hispanic_latinx,NULL)) AS latinx_2024,
    MAX(IF(report_year = 2014, race_native_american,NULL)) AS native_2014,
    MAX(IF(report_year = 2024, race_native_american,NULL)) AS native_2024,
    MAX(IF(report_year = 2014, race_white,          NULL)) AS white_2014,
    MAX(IF(report_year = 2024, race_white,          NULL)) AS white_2024,
    MAX(IF(report_year = 2014, gender_us_women,     NULL)) AS us_women_2014,
    MAX(IF(report_year = 2024, gender_us_women,     NULL)) AS us_women_2024,
    MAX(IF(report_year = 2014, gender_us_men,       NULL)) AS us_men_2014,
    MAX(IF(report_year = 2024, gender_us_men,       NULL)) AS us_men_2024,
    MAX(IF(report_year = 2014, gender_global_women, NULL)) AS global_women_2014,
    MAX(IF(report_year = 2024, gender_global_women, NULL)) AS global_women_2024,
    MAX(IF(report_year = 2014, gender_global_men,   NULL)) AS global_men_2014,
    MAX(IF(report_year = 2024, gender_global_men,   NULL)) AS global_men_2024
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year IN (2014, 2024)
)

SELECT
  SAFE_DIVIDE(asian_2024  - asian_2014 , asian_2014 ) * 100 AS asian_growth_pct,
  SAFE_DIVIDE(black_2024  - black_2014 , black_2014 ) * 100 AS black_growth_pct,
  SAFE_DIVIDE(latinx_2024 - latinx_2014, latinx_2014) * 100 AS latinx_growth_pct,
  SAFE_DIVIDE(native_2024 - native_2014, native_2014) * 100 AS native_american_growth_pct,
  SAFE_DIVIDE(white_2024  - white_2014 , white_2014 ) * 100 AS white_growth_pct,
  SAFE_DIVIDE(us_women_2024 - us_women_2014, us_women_2014) * 100 AS us_women_growth_pct,
  SAFE_DIVIDE(us_men_2024   - us_men_2014, us_men_2014)   * 100 AS us_men_growth_pct,
  SAFE_DIVIDE(global_women_2024 - global_women_2014, global_women_2014) * 100 AS global_women_growth_pct,
  SAFE_DIVIDE(global_men_2024   - global_men_2014,   global_men_2014)   * 100 AS global_men_growth_pct
FROM base;
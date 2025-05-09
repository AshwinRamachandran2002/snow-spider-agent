-- Growth rates (percent change) for the OVERALL workforce between 2014 and 2024
WITH sel AS (           -- pull the two comparison years
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
pivot AS (              -- pivot 2014 vs. 2024 into one row
  SELECT
    MAX(IF(report_year = 2014, race_asian           , NULL)) AS asian_2014,
    MAX(IF(report_year = 2024, race_asian           , NULL)) AS asian_2024,
    MAX(IF(report_year = 2014, race_black           , NULL)) AS black_2014,
    MAX(IF(report_year = 2024, race_black           , NULL)) AS black_2024,
    MAX(IF(report_year = 2014, race_hispanic_latinx , NULL)) AS latinx_2014,
    MAX(IF(report_year = 2024, race_hispanic_latinx , NULL)) AS latinx_2024,
    MAX(IF(report_year = 2014, race_native_american , NULL)) AS native_2014,
    MAX(IF(report_year = 2024, race_native_american , NULL)) AS native_2024,
    MAX(IF(report_year = 2014, race_white           , NULL)) AS white_2014,
    MAX(IF(report_year = 2024, race_white           , NULL)) AS white_2024,
    MAX(IF(report_year = 2014, gender_us_women      , NULL)) AS us_women_2014,
    MAX(IF(report_year = 2024, gender_us_women      , NULL)) AS us_women_2024,
    MAX(IF(report_year = 2014, gender_us_men        , NULL)) AS us_men_2014,
    MAX(IF(report_year = 2024, gender_us_men        , NULL)) AS us_men_2024,
    MAX(IF(report_year = 2014, gender_global_women  , NULL)) AS g_women_2014,
    MAX(IF(report_year = 2024, gender_global_women  , NULL)) AS g_women_2024,
    MAX(IF(report_year = 2014, gender_global_men    , NULL)) AS g_men_2014,
    MAX(IF(report_year = 2024, gender_global_men    , NULL)) AS g_men_2024
  FROM sel
)
SELECT
  ROUND(100 * (asian_2024  - asian_2014 ) / asian_2014 , 4) AS pct_growth_asian,
  ROUND(100 * (black_2024  - black_2014 ) / black_2014 , 4) AS pct_growth_black,
  ROUND(100 * (latinx_2024 - latinx_2014) / latinx_2014, 4) AS pct_growth_latinx,
  ROUND(100 * (native_2024 - native_2014) / native_2014, 4) AS pct_growth_native,
  ROUND(100 * (white_2024  - white_2014 ) / white_2014 , 4) AS pct_growth_white,
  ROUND(100 * (us_women_2024 - us_women_2014) / us_women_2014, 4) AS pct_growth_us_women,
  ROUND(100 * (us_men_2024   - us_men_2014  ) / us_men_2014 , 4) AS pct_growth_us_men,
  ROUND(100 * (g_women_2024  - g_women_2014 ) / g_women_2014, 4) AS pct_growth_global_women,
  ROUND(100 * (g_men_2024    - g_men_2014   ) / g_men_2014 , 4) AS pct_growth_global_men
FROM pivot;
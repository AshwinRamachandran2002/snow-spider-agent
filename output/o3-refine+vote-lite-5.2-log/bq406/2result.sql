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
  FROM base
)
SELECT 'race_asian'           AS metric, SAFE_DIVIDE(asian_2024  - asian_2014 , asian_2014 )*100 AS growth_rate_percent FROM pivot UNION ALL
SELECT 'race_black'           AS metric, SAFE_DIVIDE(black_2024  - black_2014 , black_2014 )*100                     FROM pivot UNION ALL
SELECT 'race_hispanic_latinx' AS metric, SAFE_DIVIDE(latinx_2024 - latinx_2014, latinx_2014)*100                    FROM pivot UNION ALL
SELECT 'race_native_american' AS metric, SAFE_DIVIDE(native_2024 - native_2014, native_2014)*100                    FROM pivot UNION ALL
SELECT 'race_white'           AS metric, SAFE_DIVIDE(white_2024  - white_2014 , white_2014 )*100                    FROM pivot UNION ALL
SELECT 'gender_us_women'      AS metric, SAFE_DIVIDE(us_women_2024 - us_women_2014, us_women_2014)*100              FROM pivot UNION ALL
SELECT 'gender_us_men'        AS metric, SAFE_DIVIDE(us_men_2024  - us_men_2014 , us_men_2014 )*100                 FROM pivot UNION ALL
SELECT 'gender_global_women'  AS metric, SAFE_DIVIDE(g_women_2024 - g_women_2014, g_women_2014)*100                 FROM pivot UNION ALL
SELECT 'gender_global_men'    AS metric, SAFE_DIVIDE(g_men_2024  - g_men_2014 , g_men_2014 )*100                    FROM pivot;
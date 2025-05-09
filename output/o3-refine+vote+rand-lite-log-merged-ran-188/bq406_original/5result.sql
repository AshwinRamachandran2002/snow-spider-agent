/*  Growth rates for key demographic groups in Google’s overall workforce
    between the 2014 and 2024 Diversity Annual Reports              */

WITH base AS (              -- keep only overall‑workforce rows for the two years
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

pivot AS (                  -- place 2014 and 2024 values side‑by‑side
  SELECT
    MAX(IF(report_year = 2014, race_asian,           NULL)) AS asian_2014,
    MAX(IF(report_year = 2024, race_asian,           NULL)) AS asian_2024,
    MAX(IF(report_year = 2014, race_black,           NULL)) AS black_2014,
    MAX(IF(report_year = 2024, race_black,           NULL)) AS black_2024,
    MAX(IF(report_year = 2014, race_hispanic_latinx, NULL)) AS latinx_2014,
    MAX(IF(report_year = 2024, race_hispanic_latinx, NULL)) AS latinx_2024,
    MAX(IF(report_year = 2014, race_native_american, NULL)) AS native_2014,
    MAX(IF(report_year = 2024, race_native_american, NULL)) AS native_2024,
    MAX(IF(report_year = 2014, race_white,           NULL)) AS white_2014,
    MAX(IF(report_year = 2024, race_white,           NULL)) AS white_2024,
    MAX(IF(report_year = 2014, gender_us_women,      NULL)) AS us_women_2014,
    MAX(IF(report_year = 2024, gender_us_women,      NULL)) AS us_women_2024,
    MAX(IF(report_year = 2014, gender_us_men,        NULL)) AS us_men_2014,
    MAX(IF(report_year = 2024, gender_us_men,        NULL)) AS us_men_2024,
    MAX(IF(report_year = 2014, gender_global_women,  NULL)) AS g_women_2014,
    MAX(IF(report_year = 2024, gender_global_women,  NULL)) AS g_women_2024,
    MAX(IF(report_year = 2014, gender_global_men,    NULL)) AS g_men_2014,
    MAX(IF(report_year = 2024, gender_global_men,    NULL)) AS g_men_2024
  FROM base
),

metrics AS (                -- reshape to one row per metric
  SELECT 'Asian'            AS metric, asian_2014   AS value_2014, asian_2024   AS value_2024 FROM pivot UNION ALL
  SELECT 'Black',              black_2014,             black_2024   FROM pivot UNION ALL
  SELECT 'Latinx',             latinx_2014,            latinx_2024  FROM pivot UNION ALL
  SELECT 'Native American',    native_2014,            native_2024  FROM pivot UNION ALL
  SELECT 'White',              white_2014,             white_2024   FROM pivot UNION ALL
  SELECT 'US Women',           us_women_2014,          us_women_2024 FROM pivot UNION ALL
  SELECT 'US Men',             us_men_2014,            us_men_2024  FROM pivot UNION ALL
  SELECT 'Global Women',       g_women_2014,           g_women_2024 FROM pivot UNION ALL
  SELECT 'Global Men',         g_men_2014,             g_men_2024   FROM pivot
)

SELECT
  metric,
  value_2014,
  value_2024,
  SAFE_DIVIDE(value_2024 - value_2014, value_2014) AS growth_rate   -- e.g., 0.15 = 15 % growth
FROM metrics
ORDER BY metric;
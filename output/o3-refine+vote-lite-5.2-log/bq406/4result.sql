WITH base AS (
  /* pull the 2014 and 2024 overall‑workforce figures */
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
  /* turn the two years into side‑by‑side columns */
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
    MAX(IF(report_year = 2014, gender_global_women,  NULL)) AS global_women_2014,
    MAX(IF(report_year = 2024, gender_global_women,  NULL)) AS global_women_2024,
    MAX(IF(report_year = 2014, gender_global_men,    NULL)) AS global_men_2014,
    MAX(IF(report_year = 2024, gender_global_men,    NULL)) AS global_men_2024
  FROM base
)
SELECT
  metric,
  start_value    AS value_2014,
  end_value      AS value_2024,
  SAFE_DIVIDE(end_value - start_value, start_value) AS growth_rate
FROM (
  SELECT 'asian'          AS metric, asian_2014         AS start_value, asian_2024         AS end_value FROM pivot UNION ALL
  SELECT 'black'          AS metric, black_2014         AS start_value, black_2024         AS end_value FROM pivot UNION ALL
  SELECT 'latinx'         AS metric, latinx_2014        AS start_value, latinx_2024        AS end_value FROM pivot UNION ALL
  SELECT 'native_american'AS metric, native_2014        AS start_value, native_2024        AS end_value FROM pivot UNION ALL
  SELECT 'white'          AS metric, white_2014         AS start_value, white_2024         AS end_value FROM pivot UNION ALL
  SELECT 'us_women'       AS metric, us_women_2014      AS start_value, us_women_2024      AS end_value FROM pivot UNION ALL
  SELECT 'us_men'         AS metric, us_men_2014        AS start_value, us_men_2024        AS end_value FROM pivot UNION ALL
  SELECT 'global_women'   AS metric, global_women_2014  AS start_value, global_women_2024  AS end_value FROM pivot UNION ALL
  SELECT 'global_men'     AS metric, global_men_2014    AS start_value, global_men_2024    AS end_value FROM pivot
)
ORDER BY metric;
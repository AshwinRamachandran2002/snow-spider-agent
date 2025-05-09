/* ──────────────────────────────────────────────────────────────────────────────
   Growth‑rate from 2014 → 2024 for each demographic category in Google’s
   overall workforce (non–intersectional representation table)
   --------------------------------------------------------------------------
   growth_rate_2014_to_2024 = (value_2024 – value_2014) / value_2014
   -------------------------------------------------------------------------- */
WITH base AS (
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
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year IN (2014, 2024)
)

SELECT
  metric,
  SAFE_DIVIDE(value_2024 - value_2014, value_2014) AS growth_rate_2014_to_2024
FROM base,
UNNEST([
  STRUCT('asian'            AS metric, asian_2014        AS value_2014, asian_2024        AS value_2024),
  STRUCT('black'            AS metric, black_2014        AS value_2014, black_2024        AS value_2024),
  STRUCT('latinx'           AS metric, latinx_2014       AS value_2014, latinx_2024       AS value_2024),
  STRUCT('native_american'  AS metric, native_2014       AS value_2014, native_2024       AS value_2024),
  STRUCT('white'            AS metric, white_2014        AS value_2014, white_2024        AS value_2024),
  STRUCT('us_women'         AS metric, us_women_2014     AS value_2014, us_women_2024     AS value_2024),
  STRUCT('us_men'           AS metric, us_men_2014       AS value_2014, us_men_2024       AS value_2024),
  STRUCT('global_women'     AS metric, global_women_2014 AS value_2014, global_women_2024 AS value_2024),
  STRUCT('global_men'       AS metric, global_men_2014   AS value_2014, global_men_2024   AS value_2024)
]) AS t
ORDER BY metric;
WITH base AS (
  -- keep only the two years of interest for the overall workforce
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
-- reshape so each column is a metric and each row is a year
yr AS (
  SELECT
    report_year,
    race_asian               AS asian,
    race_black               AS black,
    race_hispanic_latinx     AS latinx,
    race_native_american     AS native_american,
    race_white               AS white,
    gender_us_women          AS us_women,
    gender_us_men            AS us_men,
    gender_global_women      AS global_women,
    gender_global_men        AS global_men
  FROM base
),
-- get 2014 & 2024 values side‑by‑side
pivot AS (
  SELECT
    MAX(IF(report_year = 2014, asian            , NULL)) AS asian_2014,
    MAX(IF(report_year = 2024, asian            , NULL)) AS asian_2024,
    MAX(IF(report_year = 2014, black            , NULL)) AS black_2014,
    MAX(IF(report_year = 2024, black            , NULL)) AS black_2024,
    MAX(IF(report_year = 2014, latinx           , NULL)) AS latinx_2014,
    MAX(IF(report_year = 2024, latinx           , NULL)) AS latinx_2024,
    MAX(IF(report_year = 2014, native_american  , NULL)) AS native_american_2014,
    MAX(IF(report_year = 2024, native_american  , NULL)) AS native_american_2024,
    MAX(IF(report_year = 2014, white            , NULL)) AS white_2014,
    MAX(IF(report_year = 2024, white            , NULL)) AS white_2024,
    MAX(IF(report_year = 2014, us_women         , NULL)) AS us_women_2014,
    MAX(IF(report_year = 2024, us_women         , NULL)) AS us_women_2024,
    MAX(IF(report_year = 2014, us_men           , NULL)) AS us_men_2014,
    MAX(IF(report_year = 2024, us_men           , NULL)) AS us_men_2024,
    MAX(IF(report_year = 2014, global_women     , NULL)) AS global_women_2014,
    MAX(IF(report_year = 2024, global_women     , NULL)) AS global_women_2024,
    MAX(IF(report_year = 2014, global_men       , NULL)) AS global_men_2014,
    MAX(IF(report_year = 2024, global_men       , NULL)) AS global_men_2024
  FROM yr
)
-- assemble final result
SELECT
  metric,
  value_2014,
  value_2024,
  SAFE_DIVIDE(value_2024 - value_2014, value_2014) AS growth_rate
FROM (
  SELECT 'asian'            AS metric, asian_2014           AS value_2014, asian_2024           AS value_2024 FROM pivot UNION ALL
  SELECT 'black'            AS metric, black_2014           AS value_2014, black_2024           AS value_2024 FROM pivot UNION ALL
  SELECT 'latinx'           AS metric, latinx_2014          AS value_2014, latinx_2024          AS value_2024 FROM pivot UNION ALL
  SELECT 'native_american'  AS metric, native_american_2014 AS value_2014, native_american_2024 AS value_2024 FROM pivot UNION ALL
  SELECT 'white'            AS metric, white_2014           AS value_2014, white_2024           AS value_2024 FROM pivot UNION ALL
  SELECT 'us_women'         AS metric, us_women_2014        AS value_2014, us_women_2024        AS value_2024 FROM pivot UNION ALL
  SELECT 'us_men'           AS metric, us_men_2014          AS value_2014, us_men_2024          AS value_2024 FROM pivot UNION ALL
  SELECT 'global_women'     AS metric, global_women_2014    AS value_2014, global_women_2024    AS value_2024 FROM pivot UNION ALL
  SELECT 'global_men'       AS metric, global_men_2014      AS value_2014, global_men_2024      AS value_2024 FROM pivot
);
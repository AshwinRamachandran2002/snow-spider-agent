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
p AS (
  SELECT
    MAX(IF(report_year = 2014, race_asian,            NULL)) AS asian_2014,
    MAX(IF(report_year = 2024, race_asian,            NULL)) AS asian_2024,
    MAX(IF(report_year = 2014, race_black,            NULL)) AS black_2014,
    MAX(IF(report_year = 2024, race_black,            NULL)) AS black_2024,
    MAX(IF(report_year = 2014, race_hispanic_latinx,  NULL)) AS latinx_2014,
    MAX(IF(report_year = 2024, race_hispanic_latinx,  NULL)) AS latinx_2024,
    MAX(IF(report_year = 2014, race_native_american,  NULL)) AS native_2014,
    MAX(IF(report_year = 2024, race_native_american,  NULL)) AS native_2024,
    MAX(IF(report_year = 2014, race_white,            NULL)) AS white_2014,
    MAX(IF(report_year = 2024, race_white,            NULL)) AS white_2024,
    MAX(IF(report_year = 2014, gender_us_women,       NULL)) AS us_women_2014,
    MAX(IF(report_year = 2024, gender_us_women,       NULL)) AS us_women_2024,
    MAX(IF(report_year = 2014, gender_us_men,         NULL)) AS us_men_2014,
    MAX(IF(report_year = 2024, gender_us_men,         NULL)) AS us_men_2024,
    MAX(IF(report_year = 2014, gender_global_women,   NULL)) AS global_women_2014,
    MAX(IF(report_year = 2024, gender_global_women,   NULL)) AS global_women_2024,
    MAX(IF(report_year = 2014, gender_global_men,     NULL)) AS global_men_2014,
    MAX(IF(report_year = 2024, gender_global_men,     NULL)) AS global_men_2024
  FROM base
)
SELECT 'asian'            AS `group`, ROUND(SAFE_DIVIDE((asian_2024  - asian_2014 )*100, asian_2014 ),4) AS growth_rate_2014_2024 FROM p UNION ALL
SELECT 'black'            AS `group`, ROUND(SAFE_DIVIDE((black_2024  - black_2014 )*100, black_2014 ),4)                      FROM p UNION ALL
SELECT 'latinx'           AS `group`, ROUND(SAFE_DIVIDE((latinx_2024 - latinx_2014)*100, latinx_2014),4)                      FROM p UNION ALL
SELECT 'native_american'  AS `group`, ROUND(SAFE_DIVIDE((native_2024 - native_2014)*100, native_2014),4)                      FROM p UNION ALL
SELECT 'white'            AS `group`, ROUND(SAFE_DIVIDE((white_2024  - white_2014 )*100, white_2014 ),4)                      FROM p UNION ALL
SELECT 'us_women'         AS `group`, ROUND(SAFE_DIVIDE((us_women_2024 - us_women_2014)*100, us_women_2014),4)                FROM p UNION ALL
SELECT 'us_men'           AS `group`, ROUND(SAFE_DIVIDE((us_men_2024  - us_men_2014 )*100, us_men_2014 ),4)                   FROM p UNION ALL
SELECT 'global_women'     AS `group`, ROUND(SAFE_DIVIDE((global_women_2024 - global_women_2014)*100, global_women_2014),4)    FROM p UNION ALL
SELECT 'global_men'       AS `group`, ROUND(SAFE_DIVIDE((global_men_2024  - global_men_2014 )*100, global_men_2014 ),4)       FROM p
ORDER BY `group`;
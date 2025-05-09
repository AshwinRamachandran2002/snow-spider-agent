-- 2014 → 2024 growth rates for race & gender segments
WITH overall_yr AS (
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
)

SELECT
  ROUND(100 * (MAX(IF(report_year = 2024, race_asian          , NULL)) -
               MAX(IF(report_year = 2014, race_asian          , NULL)))
               / MAX(IF(report_year = 2014, race_asian          , NULL)), 2) AS growth_pct_race_asian,

  ROUND(100 * (MAX(IF(report_year = 2024, race_black          , NULL)) -
               MAX(IF(report_year = 2014, race_black          , NULL)))
               / MAX(IF(report_year = 2014, race_black          , NULL)), 2) AS growth_pct_race_black,

  ROUND(100 * (MAX(IF(report_year = 2024, race_hispanic_latinx , NULL)) -
               MAX(IF(report_year = 2014, race_hispanic_latinx , NULL)))
               / MAX(IF(report_year = 2014, race_hispanic_latinx , NULL)), 2) AS growth_pct_race_latinx,

  ROUND(100 * (MAX(IF(report_year = 2024, race_native_american, NULL)) -
               MAX(IF(report_year = 2014, race_native_american, NULL)))
               / MAX(IF(report_year = 2014, race_native_american, NULL)), 2) AS growth_pct_race_native_american,

  ROUND(100 * (MAX(IF(report_year = 2024, race_white          , NULL)) -
               MAX(IF(report_year = 2014, race_white          , NULL)))
               / MAX(IF(report_year = 2014, race_white          , NULL)), 2) AS growth_pct_race_white,

  ROUND(100 * (MAX(IF(report_year = 2024, gender_us_women     , NULL)) -
               MAX(IF(report_year = 2014, gender_us_women     , NULL)))
               / MAX(IF(report_year = 2014, gender_us_women     , NULL)), 2) AS growth_pct_us_women,

  ROUND(100 * (MAX(IF(report_year = 2024, gender_us_men       , NULL)) -
               MAX(IF(report_year = 2014, gender_us_men       , NULL)))
               / MAX(IF(report_year = 2014, gender_us_men       , NULL)), 2) AS growth_pct_us_men,

  ROUND(100 * (MAX(IF(report_year = 2024, gender_global_women , NULL)) -
               MAX(IF(report_year = 2014, gender_global_women , NULL)))
               / MAX(IF(report_year = 2014, gender_global_women , NULL)), 2) AS growth_pct_global_women,

  ROUND(100 * (MAX(IF(report_year = 2024, gender_global_men   , NULL)) -
               MAX(IF(report_year = 2014, gender_global_men   , NULL)))
               / MAX(IF(report_year = 2014, gender_global_men   , NULL)), 2) AS growth_pct_global_men
FROM overall_yr;
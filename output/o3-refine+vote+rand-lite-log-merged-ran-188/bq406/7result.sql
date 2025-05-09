/*  Growth rates for Asians, Black people, Latinx people, Native Americans, White people,
    U.S. women, U.S. men, global women, and global men
    between 2014 and 2024 (or the latest available year if 2024 is absent)
    – overall workforce                                             */

WITH target_year AS (      -- pick 2024 if it exists, otherwise use latest
  SELECT
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
        WHERE workforce = 'overall' AND report_year = 2024
      )
      THEN 2024
      ELSE (
        SELECT MAX(report_year)
        FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
        WHERE workforce = 'overall'
      )
    END AS yr
),
baseline_2014 AS (
  SELECT
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
    AND report_year = 2014
),
snapshot AS (
  SELECT
    d.report_year,
    d.race_asian,
    d.race_black,
    d.race_hispanic_latinx,
    d.race_native_american,
    d.race_white,
    d.gender_us_women,
    d.gender_us_men,
    d.gender_global_women,
    d.gender_global_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation` AS d
  CROSS JOIN target_year
  WHERE d.workforce   = 'overall'
    AND d.report_year = target_year.yr
)
SELECT
  snapshot.report_year                            AS comparison_year,        -- 2024 or latest
  ROUND((snapshot.race_asian           - baseline_2014.race_asian          ) / baseline_2014.race_asian          , 4) AS growth_rate_asian,
  ROUND((snapshot.race_black           - baseline_2014.race_black          ) / baseline_2014.race_black          , 4) AS growth_rate_black,
  ROUND((snapshot.race_hispanic_latinx - baseline_2014.race_hispanic_latinx) / baseline_2014.race_hispanic_latinx, 4) AS growth_rate_latinx,
  ROUND((snapshot.race_native_american - baseline_2014.race_native_american) / baseline_2014.race_native_american, 4) AS growth_rate_native,
  ROUND((snapshot.race_white           - baseline_2014.race_white          ) / baseline_2014.race_white          , 4) AS growth_rate_white,
  ROUND((snapshot.gender_us_women      - baseline_2014.gender_us_women     ) / baseline_2014.gender_us_women     , 4) AS growth_rate_us_women,
  ROUND((snapshot.gender_us_men        - baseline_2014.gender_us_men       ) / baseline_2014.gender_us_men       , 4) AS growth_rate_us_men,
  ROUND((snapshot.gender_global_women  - baseline_2014.gender_global_women ) / baseline_2014.gender_global_women , 4) AS growth_rate_global_women,
  ROUND((snapshot.gender_global_men    - baseline_2014.gender_global_men   ) / baseline_2014.gender_global_men   , 4) AS growth_rate_global_men
FROM baseline_2014
CROSS JOIN snapshot;
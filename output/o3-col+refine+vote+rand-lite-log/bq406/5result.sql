/*  Growth rates (percent change) from 2014 → 2024 for the “overall” workforce */
WITH vals AS (
  SELECT
    MAX(CASE WHEN report_year = 2014 THEN race_asian          END) AS race_asian_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_asian          END) AS race_asian_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_black          END) AS race_black_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_black          END) AS race_black_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_hispanic_latinx END) AS race_lat_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_hispanic_latinx END) AS race_lat_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_native_american END) AS race_nat_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_native_american END) AS race_nat_2024,
    MAX(CASE WHEN report_year = 2014 THEN race_white          END) AS race_white_2014,
    MAX(CASE WHEN report_year = 2024 THEN race_white          END) AS race_white_2024,
    MAX(CASE WHEN report_year = 2014 THEN gender_us_women     END) AS us_women_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_us_women     END) AS us_women_2024,
    MAX(CASE WHEN report_year = 2014 THEN gender_us_men       END) AS us_men_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_us_men       END) AS us_men_2024,
    MAX(CASE WHEN report_year = 2014 THEN gender_global_women END) AS glb_women_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_global_women END) AS glb_women_2024,
    MAX(CASE WHEN report_year = 2014 THEN gender_global_men   END) AS glb_men_2014,
    MAX(CASE WHEN report_year = 2024 THEN gender_global_men   END) AS glb_men_2024
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year IN (2014, 2024)
)

SELECT
  ROUND(100 * (race_asian_2024  - race_asian_2014 ) / race_asian_2014 , 4) AS growth_pct_race_asian,
  ROUND(100 * (race_black_2024  - race_black_2014 ) / race_black_2014 , 4) AS growth_pct_race_black,
  ROUND(100 * (race_lat_2024    - race_lat_2014   ) / race_lat_2014   , 4) AS growth_pct_race_hispanic_latinx,
  ROUND(100 * (race_nat_2024    - race_nat_2014   ) / race_nat_2014   , 4) AS growth_pct_race_native_american,
  ROUND(100 * (race_white_2024  - race_white_2014 ) / race_white_2014 , 4) AS growth_pct_race_white,
  ROUND(100 * (us_women_2024    - us_women_2014   ) / us_women_2014   , 4) AS growth_pct_gender_us_women,
  ROUND(100 * (us_men_2024      - us_men_2014     ) / us_men_2014     , 4) AS growth_pct_gender_us_men,
  ROUND(100 * (glb_women_2024   - glb_women_2014  ) / glb_women_2014  , 4) AS growth_pct_gender_global_women,
  ROUND(100 * (glb_men_2024     - glb_men_2014    ) / glb_men_2014    , 4) AS growth_pct_gender_global_men
FROM vals;
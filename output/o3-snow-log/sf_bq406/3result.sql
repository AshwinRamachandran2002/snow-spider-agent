WITH vals AS (
    SELECT
        MAX(CASE WHEN "report_year" = 2014 THEN "race_asian"            END) AS asian_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_asian"            END) AS asian_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_black"            END) AS black_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_black"            END) AS black_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_hispanic_latinx"  END) AS latinx_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_hispanic_latinx"  END) AS latinx_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_native_american"  END) AS native_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_native_american"  END) AS native_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_white"            END) AS white_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_white"            END) AS white_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_women"       END) AS us_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_women"       END) AS us_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_men"         END) AS us_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_men"         END) AS us_men_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_women"   END) AS global_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_women"   END) AS global_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_men"     END) AS global_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_men"     END) AS global_men_2024
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" IN (2014, 2024)
)

SELECT 'Asian'            AS metric,
       asian_2014         AS value_2014,
       asian_2024         AS value_2024,
       (asian_2024  - asian_2014 ) / asian_2014  AS growth_rate
FROM vals

UNION ALL
SELECT 'Black',  black_2014,  black_2024,  (black_2024  - black_2014 ) / black_2014  FROM vals
UNION ALL
SELECT 'Latinx', latinx_2014, latinx_2024, (latinx_2024 - latinx_2014) / latinx_2014 FROM vals
UNION ALL
SELECT 'Native American', native_2014, native_2024, (native_2024 - native_2014) / native_2014 FROM vals
UNION ALL
SELECT 'White',  white_2014,  white_2024,  (white_2024  - white_2014 ) / white_2014  FROM vals
UNION ALL
SELECT 'US Women',   us_women_2014,   us_women_2024,   (us_women_2024   - us_women_2014 ) / us_women_2014   FROM vals
UNION ALL
SELECT 'US Men',     us_men_2014,     us_men_2024,     (us_men_2024     - us_men_2014 ) / us_men_2014     FROM vals
UNION ALL
SELECT 'Global Women', global_women_2014, global_women_2024,
       (global_women_2024 - global_women_2014) / global_women_2014 FROM vals
UNION ALL
SELECT 'Global Men',   global_men_2014,   global_men_2024,
       (global_men_2024   - global_men_2014 ) / global_men_2014   FROM vals;
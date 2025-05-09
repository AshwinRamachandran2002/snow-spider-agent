WITH base AS (
    /* pick the two comparison years for the overall workforce */
    SELECT
        "report_year",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_native_american",
        "race_white",
        "gender_us_women",
        "gender_us_men",
        "gender_global_women",
        "gender_global_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" IN (2014, 2024)
), yr_vals AS (
    /* pivot 2014 and 2024 values into one row */
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
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_women"   END) AS glob_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_women"   END) AS glob_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_men"     END) AS glob_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_men"     END) AS glob_men_2024
    FROM base
), growths AS (
    /* calculate growth rates: (2024 - 2014) / 2014 */
    SELECT 'asian'          AS metric, (asian_2024  - asian_2014 ) / asian_2014   AS growth_rate FROM yr_vals UNION ALL
    SELECT 'black'          AS metric, (black_2024  - black_2014 ) / black_2014   FROM yr_vals UNION ALL
    SELECT 'latinx'         AS metric, (latinx_2024 - latinx_2014) / latinx_2014  FROM yr_vals UNION ALL
    SELECT 'native_american'AS metric, (native_2024 - native_2014) / native_2014  FROM yr_vals UNION ALL
    SELECT 'white'          AS metric, (white_2024  - white_2014 ) / white_2014   FROM yr_vals UNION ALL
    SELECT 'us_women'       AS metric, (us_women_2024- us_women_2014)/us_women_2014 FROM yr_vals UNION ALL
    SELECT 'us_men'         AS metric, (us_men_2024 - us_men_2014 )/us_men_2014   FROM yr_vals UNION ALL
    SELECT 'global_women'   AS metric, (glob_women_2024- glob_women_2014)/glob_women_2014 FROM yr_vals UNION ALL
    SELECT 'global_men'     AS metric, (glob_men_2024 - glob_men_2014)/glob_men_2014 FROM yr_vals
)
SELECT
    metric,
    ROUND(growth_rate, 6) AS growth_rate   -- keep 6‐decimal precision; adjust if needed
FROM growths
ORDER BY metric;
WITH base AS (
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
), pivot AS (
    SELECT
        MAX(CASE WHEN "report_year" = 2014 THEN "race_asian"          END) AS race_asian_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_asian"          END) AS race_asian_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_black"          END) AS race_black_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_black"          END) AS race_black_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_hispanic_latinx"END) AS race_latino_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_hispanic_latinx"END) AS race_latino_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_native_american"END) AS race_native_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_native_american"END) AS race_native_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_white"          END) AS race_white_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_white"          END) AS race_white_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_women"     END) AS us_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_women"     END) AS us_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_men"       END) AS us_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_men"       END) AS us_men_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_women" END) AS global_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_women" END) AS global_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_men"   END) AS global_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_men"   END) AS global_men_2024
    FROM base
)
SELECT
    ROUND(100 * (race_asian_2024  - race_asian_2014 ) / NULLIF(race_asian_2014 ,0), 4) AS "growth_rate_race_asian_pct",
    ROUND(100 * (race_black_2024  - race_black_2014 ) / NULLIF(race_black_2014 ,0), 4) AS "growth_rate_race_black_pct",
    ROUND(100 * (race_latino_2024 - race_latino_2014) / NULLIF(race_latino_2014,0), 4) AS "growth_rate_race_latinx_pct",
    ROUND(100 * (race_native_2024 - race_native_2014) / NULLIF(race_native_2014,0), 4) AS "growth_rate_race_native_american_pct",
    ROUND(100 * (race_white_2024  - race_white_2014 ) / NULLIF(race_white_2014 ,0), 4) AS "growth_rate_race_white_pct",
    ROUND(100 * (us_women_2024    - us_women_2014   ) / NULLIF(us_women_2014  ,0), 4) AS "growth_rate_us_women_pct",
    ROUND(100 * (us_men_2024      - us_men_2014     ) / NULLIF(us_men_2014    ,0), 4) AS "growth_rate_us_men_pct",
    ROUND(100 * (global_women_2024- global_women_2014) / NULLIF(global_women_2014,0), 4) AS "growth_rate_global_women_pct",
    ROUND(100 * (global_men_2024  - global_men_2014 ) / NULLIF(global_men_2014 ,0), 4) AS "growth_rate_global_men_pct"
FROM pivot;
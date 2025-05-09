/*  Growth rates (2014 → 2024) for overall Google workforce           */
/*  If any 2014 denominator is 0 the result will be NULL to avoid div/0 */

WITH base AS (   -- keep only the two required years
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
),
yr AS (          -- put 2014 and 2024 values onto the same row
    SELECT
        MAX(CASE WHEN "report_year" = 2014 THEN "race_asian"           END) AS asian_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_asian"           END) AS asian_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_black"           END) AS black_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_black"           END) AS black_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_hispanic_latinx" END) AS latinx_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_hispanic_latinx" END) AS latinx_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_native_american" END) AS native_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_native_american" END) AS native_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "race_white"           END) AS white_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_white"           END) AS white_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_women"      END) AS us_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_women"      END) AS us_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_men"        END) AS us_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_men"        END) AS us_men_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_women"  END) AS global_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_women"  END) AS global_women_2024,
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_men"    END) AS global_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_men"    END) AS global_men_2024
    FROM base
),
growth AS (
    SELECT
        (asian_2024  - asian_2014 ) / NULLIF(asian_2014 ,0)  AS "ASIAN_GROWTH_RATE",
        (black_2024  - black_2014 ) / NULLIF(black_2014 ,0)  AS "BLACK_GROWTH_RATE",
        (latinx_2024 - latinx_2014) / NULLIF(latinx_2014,0)  AS "LATINX_GROWTH_RATE",
        (native_2024 - native_2014) / NULLIF(native_2014,0)  AS "NATIVE_AMERICAN_GROWTH_RATE",
        (white_2024  - white_2014 ) / NULLIF(white_2014 ,0)  AS "WHITE_GROWTH_RATE",
        (us_women_2024 - us_women_2014) / NULLIF(us_women_2014,0)  AS "US_WOMEN_GROWTH_RATE",
        (us_men_2024   - us_men_2014 ) / NULLIF(us_men_2014 ,0)    AS "US_MEN_GROWTH_RATE",
        (global_women_2024 - global_women_2014) / NULLIF(global_women_2014,0) AS "GLOBAL_WOMEN_GROWTH_RATE",
        (global_men_2024   - global_men_2014 ) / NULLIF(global_men_2014 ,0)   AS "GLOBAL_MEN_GROWTH_RATE"
    FROM yr
)
SELECT * FROM growth;
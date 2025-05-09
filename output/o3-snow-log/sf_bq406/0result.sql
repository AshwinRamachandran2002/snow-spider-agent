WITH base AS (
    SELECT
        MAX(CASE WHEN "report_year" = 2014 THEN "race_asian"          END) AS race_asian_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_asian"          END) AS race_asian_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "race_black"          END) AS race_black_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_black"          END) AS race_black_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "race_hispanic_latinx" END) AS race_latinx_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_hispanic_latinx" END) AS race_latinx_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "race_native_american" END) AS race_native_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_native_american" END) AS race_native_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "race_white"          END) AS race_white_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "race_white"          END) AS race_white_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_women"     END) AS us_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_women"     END) AS us_women_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_men"       END) AS us_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_men"       END) AS us_men_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_women" END) AS gbl_women_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_women" END) AS gbl_women_2024,
        
        MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_men"   END) AS gbl_men_2014,
        MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_men"   END) AS gbl_men_2024
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" IN (2014, 2024)
)
SELECT
    ROUND( (race_asian_2024  - race_asian_2014)  / NULLIF(race_asian_2014 ,0) * 100 , 4) AS "asian_growth_pct",
    ROUND( (race_black_2024  - race_black_2014)  / NULLIF(race_black_2014 ,0) * 100 , 4) AS "black_growth_pct",
    ROUND( (race_latinx_2024 - race_latinx_2014) / NULLIF(race_latinx_2014,0) * 100 , 4) AS "latinx_growth_pct",
    ROUND( (race_native_2024 - race_native_2014) / NULLIF(race_native_2014,0) * 100 , 4) AS "native_american_growth_pct",
    ROUND( (race_white_2024  - race_white_2014)  / NULLIF(race_white_2014 ,0) * 100 , 4) AS "white_growth_pct",
    
    ROUND( (us_women_2024 - us_women_2014) / NULLIF(us_women_2014,0) * 100 , 4)          AS "us_women_growth_pct",
    ROUND( (us_men_2024   - us_men_2014)   / NULLIF(us_men_2014  ,0) * 100 , 4)          AS "us_men_growth_pct",
    
    ROUND( (gbl_women_2024 - gbl_women_2014) / NULLIF(gbl_women_2014,0) * 100 , 4)       AS "global_women_growth_pct",
    ROUND( (gbl_men_2024   - gbl_men_2014)   / NULLIF(gbl_men_2014  ,0) * 100 , 4)       AS "global_men_growth_pct"
FROM base;
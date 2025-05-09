-- growth rates 2014 → 2024, overall workforce
WITH base AS (
    SELECT  "report_year",
            "race_asian",
            "race_black",
            "race_hispanic_latinx",
            "race_native_american",
            "race_white",
            "gender_us_women",
            "gender_us_men",
            "gender_global_women",
            "gender_global_men"
    FROM    GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE   "workforce" = 'overall'
      AND   "report_year" IN (2014, 2024)
), pivot AS (
    -- Asian
    SELECT  'race_asian'          AS metric,
            MAX(CASE WHEN "report_year" = 2014 THEN "race_asian"          END) AS value_2014,
            MAX(CASE WHEN "report_year" = 2024 THEN "race_asian"          END) AS value_2024
    FROM base
    UNION ALL
    -- Black or African American
    SELECT  'race_black',
            MAX(CASE WHEN "report_year" = 2014 THEN "race_black"          END),
            MAX(CASE WHEN "report_year" = 2024 THEN "race_black"          END)
    FROM base
    UNION ALL
    -- Latinx / Hispanic
    SELECT  'race_hispanic_latinx',
            MAX(CASE WHEN "report_year" = 2014 THEN "race_hispanic_latinx" END),
            MAX(CASE WHEN "report_year" = 2024 THEN "race_hispanic_latinx" END)
    FROM base
    UNION ALL
    -- Native American
    SELECT  'race_native_american',
            MAX(CASE WHEN "report_year" = 2014 THEN "race_native_american" END),
            MAX(CASE WHEN "report_year" = 2024 THEN "race_native_american" END)
    FROM base
    UNION ALL
    -- White
    SELECT  'race_white',
            MAX(CASE WHEN "report_year" = 2014 THEN "race_white"          END),
            MAX(CASE WHEN "report_year" = 2024 THEN "race_white"          END)
    FROM base
    UNION ALL
    -- U.S. Women
    SELECT  'gender_us_women',
            MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_women"     END),
            MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_women"     END)
    FROM base
    UNION ALL
    -- U.S. Men
    SELECT  'gender_us_men',
            MAX(CASE WHEN "report_year" = 2014 THEN "gender_us_men"       END),
            MAX(CASE WHEN "report_year" = 2024 THEN "gender_us_men"       END)
    FROM base
    UNION ALL
    -- Global Women
    SELECT  'gender_global_women',
            MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_women" END),
            MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_women" END)
    FROM base
    UNION ALL
    -- Global Men
    SELECT  'gender_global_men',
            MAX(CASE WHEN "report_year" = 2014 THEN "gender_global_men"   END),
            MAX(CASE WHEN "report_year" = 2024 THEN "gender_global_men"   END)
    FROM base
)
SELECT  metric,
        value_2014,
        value_2024,
        CASE 
            WHEN value_2014 IS NOT NULL 
                 AND value_2024 IS NOT NULL 
                 AND value_2014 <> 0
            THEN (value_2024 - value_2014) / value_2014
        END AS growth_rate
FROM    pivot
ORDER BY metric;
/*  Combined 2021 race & U.S. gender distributions
    – Google overall hiring
    – Google overall representation
    – BLS tech-sector (Internet publishing … OR Computer systems design …) employment-weighted average
*/

WITH google AS (  ------------------------------------------------------ Google data
    SELECT
        'Google_Hiring'              AS "category",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women"            AS "percent_women",
        "gender_us_men"              AS "percent_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "workforce"  = 'overall'
      AND "report_year" = 2021

    UNION ALL

    SELECT
        'Google_Representation',
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce"  = 'overall'
      AND "report_year" = 2021
),
bls AS (  -------------------------------------------------------------- BLS tech sectors
    SELECT
        'BLS_Tech_WeightedAvg'                                    AS "category",
        /* employment-weighted racial shares */
        SUM("total_employed_in_thousands" * "percent_asian")   / SUM("total_employed_in_thousands")  AS "race_asian",
        SUM("total_employed_in_thousands" * "percent_black_or_african_american") / SUM("total_employed_in_thousands")  AS "race_black",
        SUM("total_employed_in_thousands" * "percent_hispanic_or_latino")        / SUM("total_employed_in_thousands")  AS "race_hispanic_latinx",
        SUM("total_employed_in_thousands" * "percent_white")    / SUM("total_employed_in_thousands")  AS "race_white",
        /* employment-weighted gender shares */
        SUM("total_employed_in_thousands" * "percent_women")    / SUM("total_employed_in_thousands")  AS "percent_women",
        1 - ( SUM("total_employed_in_thousands" * "percent_women") / SUM("total_employed_in_thousands") ) AS "percent_men"
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND (
              "subsector"      ILIKE '%internet%publishing%'            -- Internet publishing & web search portals
           OR "industry_group" ILIKE '%systems design%'                 -- Computer systems design & related services
          )
)
----------------------------------------------------------------------- Final combined view
SELECT
    "category",
    "race_asian",
    "race_black",
    "race_hispanic_latinx",
    "race_white",
    "percent_women",
    "percent_men"
FROM google
UNION ALL
SELECT
    "category",
    "race_asian",
    "race_black",
    "race_hispanic_latinx",
    "race_white",
    "percent_women",
    "percent_men"
FROM bls
ORDER BY "category";
WITH google_hiring AS (
    -- Google 2021 overall HIRING profile
    SELECT
        'Google Hiring'                                   AS "category",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women"                                 AS "gender_women",
        "gender_us_men"                                   AS "gender_men"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
    WHERE "report_year" = 2021
      AND "workforce"   = 'overall'
),
google_representation AS (
    -- Google 2021 overall REPRESENTATION profile
    SELECT
        'Google Representation'                           AS "category",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women"                                 AS "gender_women",
        "gender_us_men"                                   AS "gender_men"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_REPRESENTATION"
    WHERE "report_year" = 2021
      AND "workforce"   = 'overall'
),
bls_tech AS (
    -- 2021 BLS tech-sector weighted averages
    SELECT
        'BLS Tech Sectors'                                AS "category",
        SUM("percent_asian"                      * "total_employed_in_thousands")
            / SUM("total_employed_in_thousands")          AS "race_asian",
        SUM("percent_black_or_african_american" * "total_employed_in_thousands")
            / SUM("total_employed_in_thousands")          AS "race_black",
        SUM("percent_hispanic_or_latino"         * "total_employed_in_thousands")
            / SUM("total_employed_in_thousands")          AS "race_hispanic_latinx",
        SUM("percent_white"                      * "total_employed_in_thousands")
            / SUM("total_employed_in_thousands")          AS "race_white",
        SUM("percent_women"                      * "total_employed_in_thousands")
            / SUM("total_employed_in_thousands")          AS "gender_women",
        SUM((1.0 - "percent_women")              * "total_employed_in_thousands")
            / SUM("total_employed_in_thousands")          AS "gender_men"
    FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
    WHERE "year" = 2021
      AND (
              "industry_group" ILIKE '%computer%system%design%'
           OR "industry_group" ILIKE '%internet%publishing%'
           OR "industry"       ILIKE '%computer%system%design%'
           OR "industry"       ILIKE '%internet%publishing%'
          )
)
-- Combine the three snapshots into one comparison table
SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_tech;
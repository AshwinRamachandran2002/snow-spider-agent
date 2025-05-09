/* -------------------------------------------------------------
   Combined 2021 racial & gender snapshot
   • Google overall hiring
   • Google overall workforce representation
   • BLS tech-sector workforce (Internet publishing … + Computer systems design …)
   ------------------------------------------------------------- */
WITH google_hiring AS (   -- Google 2021 overall hiring
    SELECT
        'Google Hiring (Overall 2021)'                      AS "source",
        "race_asian"                                        AS "race_asian",
        "race_black"                                        AS "race_black",
        "race_hispanic_latinx"                              AS "race_hispanic_latinx",
        "race_white"                                        AS "race_white",
        "gender_us_women"                                   AS "gender_us_women",
        "gender_us_men"                                     AS "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "report_year" = 2021
      AND "workforce"   = 'overall'
),

google_representation AS (   -- Google 2021 overall workforce representation
    SELECT
        'Google Workforce Representation (Overall 2021)'    AS "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "report_year" = 2021
      AND "workforce"   = 'overall'
),

bls_tech AS (   -- 2021 BLS tech-sector weighted averages
    SELECT
        'BLS Tech Sectors (Weighted Avg 2021)'              AS "source",
        ROUND(SUM("total_employed_in_thousands" * "percent_asian")             / SUM("total_employed_in_thousands"), 3)  AS "race_asian",
        ROUND(SUM("total_employed_in_thousands" * "percent_black_or_african_american") / SUM("total_employed_in_thousands"), 3)  AS "race_black",
        ROUND(SUM("total_employed_in_thousands" * "percent_hispanic_or_latino")         / SUM("total_employed_in_thousands"), 3)  AS "race_hispanic_latinx",
        ROUND(SUM("total_employed_in_thousands" * "percent_white")              / SUM("total_employed_in_thousands"), 3)  AS "race_white",
        ROUND(SUM("total_employed_in_thousands" * "percent_women")              / SUM("total_employed_in_thousands"), 3)  AS "gender_us_women",
        ROUND(1 - (SUM("total_employed_in_thousands" * "percent_women")         / SUM("total_employed_in_thousands")), 3) AS "gender_us_men"
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND "subsector" IN (
          'Internet publishing and broadcasting and web search portals',
          'Computer systems design and related services'
      )
)

-- Consolidated output
SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_tech;
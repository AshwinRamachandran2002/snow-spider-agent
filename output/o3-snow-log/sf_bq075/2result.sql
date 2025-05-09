/* -----------------------------------------------------------
   2021 – Racial & Gender Distribution Comparison
   • Google overall workforce – Hiring
   • Google overall workforce – Representation
   • BLS tech sectors – Employment-weighted snapshot
-------------------------------------------------------------*/
WITH google_hiring AS (      -- Google overall hiring (2021)
    SELECT
        'Google - Hiring (Overall)'                AS "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),
google_rep AS (              -- Google overall representation (2021)
    SELECT
        'Google - Representation (Overall)'        AS "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),
bls_tech AS (                -- Employment-weighted tech-sector averages (2021)
    SELECT
        'BLS - Tech Sectors (Emp-weighted)'        AS "source",
        /* race shares */
        SUM("total_employed_in_thousands" * COALESCE("percent_asian",0)) /
        SUM("total_employed_in_thousands")         AS "race_asian",
        SUM("total_employed_in_thousands" * COALESCE("percent_black_or_african_american",0)) /
        SUM("total_employed_in_thousands")         AS "race_black",
        SUM("total_employed_in_thousands" * COALESCE("percent_hispanic_or_latino",0)) /
        SUM("total_employed_in_thousands")         AS "race_hispanic_latinx",
        SUM("total_employed_in_thousands" * COALESCE("percent_white",0)) /
        SUM("total_employed_in_thousands")         AS "race_white",
        /* women share (men will be derived later) */
        SUM("total_employed_in_thousands" * COALESCE("percent_women",0)) /
        SUM("total_employed_in_thousands")         AS "gender_us_women"
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND (
              COALESCE("subsector",'')      ILIKE '%Internet publishing and broadcasting and web search portals%'
           OR COALESCE("industry_group",'') ILIKE '%Internet publishing and broadcasting and web search portals%'
           OR COALESCE("industry",'')       ILIKE '%Internet publishing and broadcasting and web search portals%'
           OR COALESCE("subsector",'')      ILIKE '%Computer systems design%'
           OR COALESCE("industry_group",'') ILIKE '%Computer systems design%'
           OR COALESCE("industry",'')       ILIKE '%Computer systems design%'
          )
),
combined AS (
    /* Google hiring */
    SELECT
        "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM google_hiring
    UNION ALL
    /* Google representation */
    SELECT
        "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM google_rep
    UNION ALL
    /* BLS tech snapshot (derive men = 1 - women) */
    SELECT
        "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        1 - "gender_us_women"                 AS "gender_us_men"
    FROM bls_tech
)
SELECT
    "source",
    ROUND("race_asian",           3) AS "race_asian",
    ROUND("race_black",           3) AS "race_black",
    ROUND("race_hispanic_latinx", 3) AS "race_hispanic_latinx",
    ROUND("race_white",           3) AS "race_white",
    ROUND("gender_us_women",      3) AS "gender_us_women",
    ROUND("gender_us_men",        3) AS "gender_us_men"
FROM combined
ORDER BY "source";
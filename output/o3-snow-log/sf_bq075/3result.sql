/* 2021 – Google vs. BLS tech-sector race & gender shares */

WITH google_rep AS (   -- Google overall workforce representation
    SELECT
        'Google Workforce Representation'           AS "source",
        "race_asian"                                AS "asian",
        "race_black"                                AS "black",
        "race_hispanic_latinx"                      AS "hispanic_latinx",
        "race_white"                                AS "white",
        "gender_us_women"                           AS "women",
        "gender_us_men"                             AS "men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
), google_hire AS (    -- Google overall workforce hiring
    SELECT
        'Google Workforce Hiring'                   AS "source",
        "race_asian"                                AS "asian",
        "race_black"                                AS "black",
        "race_hispanic_latinx"                      AS "hispanic_latinx",
        "race_white"                                AS "white",
        "gender_us_women"                           AS "women",
        "gender_us_men"                             AS "men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
), bls_ip AS (        -- BLS: Internet publishing & web search portals
    SELECT
        'BLS – Internet publishing & web search'    AS "source",
        "percent_asian"                             AS "asian",
        "percent_black_or_african_american"         AS "black",
        "percent_hispanic_or_latino"                AS "hispanic_latinx",
        "percent_white"                             AS "white",
        "percent_women"                             AS "women",
        1 - "percent_women"                         AS "men"
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND "subsector" ILIKE '%internet%publishing%web%search%'
), bls_cs AS (        -- BLS: Computer systems design & related services
    SELECT
        'BLS – Computer systems design & related services' AS "source",
        "percent_asian"                             AS "asian",
        "percent_black_or_african_american"         AS "black",
        "percent_hispanic_or_latino"                AS "hispanic_latinx",
        "percent_white"                             AS "white",
        "percent_women"                             AS "women",
        1 - "percent_women"                         AS "men"
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND "subsector" ILIKE '%computer%systems%design%'
)

SELECT *
FROM (
    SELECT * FROM google_rep
    UNION ALL
    SELECT * FROM google_hire
    UNION ALL
    SELECT * FROM bls_ip
    UNION ALL
    SELECT * FROM bls_cs
)
ORDER BY "source";
/*---------------------------------------------------------------
  2021 snapshot:  Google overall-workforce hiring & representation
  compared with BLS tech-sector workforce (Internet publishing &
  Computer systems design).  All percentages are already stored
  as shares (e.g., 0.428 = 42.8%) so no further scaling needed.
----------------------------------------------------------------*/
SELECT
        'GOOGLE_HIRING'                       AS "source",
        'Overall Workforce – Hiring'          AS "category",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women"                     AS "women_us",
        "gender_us_men"                       AS "men_us"
FROM    GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
WHERE   "report_year" = 2021
  AND   "workforce"   ILIKE '%overall%'

UNION ALL
SELECT
        'GOOGLE_REPRESENTATION'               AS "source",
        'Overall Workforce – Representation'  AS "category",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women"                     AS "women_us",
        "gender_us_men"                       AS "men_us"
FROM    GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
WHERE   "report_year" = 2021
  AND   "workforce"   ILIKE '%overall%'

UNION ALL
SELECT
        'BLS_TECH'                            AS "source",
        /* explicit label for the two tech segments of interest */
        CASE
             WHEN "industry_group" ILIKE '%internet publishing%' THEN
                  'Internet publishing & web search portals'
             WHEN "industry_group" ILIKE '%computer systems design%' THEN
                  'Computer systems design & related services'
             ELSE COALESCE(NULLIF("industry_group", ''),
                           NULLIF("subsector", ''),
                           NULLIF("industry", ''))
        END                                   AS "category",
        "percent_asian"                       AS "race_asian",
        "percent_black_or_african_american"   AS "race_black",
        "percent_hispanic_or_latino"          AS "race_hispanic_latinx",
        "percent_white"                       AS "race_white",
        "percent_women"                       AS "women_us",
        (1 - "percent_women")                 AS "men_us"
FROM    GOOGLE_DEI.BLS.CPSAAT18
WHERE   "year" = 2021
  AND   (
           /* Internet publishing / web-portal segment */
           UPPER(COALESCE("industry_group", ''))   LIKE '%INTERNET PUBLISHING%'
        OR UPPER(COALESCE("industry", ''))         LIKE '%WEB SEARCH PORTALS%'
        /* Computer systems design segment */
        OR UPPER(COALESCE("industry_group", ''))   LIKE '%COMPUTER SYSTEMS DESIGN%'
        OR UPPER(COALESCE("subsector", ''))        LIKE '%COMPUTER%SYSTEMS%DESIGN%'
      )

ORDER BY
        "source",
        "category";
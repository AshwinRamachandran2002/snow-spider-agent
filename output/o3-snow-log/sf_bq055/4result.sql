/*  Top-3 races with the largest absolute percentage gaps between
    Google 2021 overall hiring and 2021 BLS tech-sector averages     */
WITH google AS (   -- Google overall hiring, 2021
    SELECT
        "race_asian"            AS g_asian,
        "race_black"            AS g_black,
        "race_hispanic_latinx"  AS g_hispanic,
        "race_white"            AS g_white
    FROM GOOGLE_DEI.GOOGLE_DEI."DAR_NON_INTERSECTIONAL_HIRING"
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),
bls AS (          -- BLS tech-sector workforce averages, 2021
    SELECT
        AVG("percent_asian")                     AS b_asian,
        AVG("percent_black_or_african_american") AS b_black,
        AVG("percent_hispanic_or_latino")        AS b_hispanic,
        AVG("percent_white")                     AS b_white
    FROM GOOGLE_DEI.BLS."CPSAAT18"
    WHERE "year" = 2021
      AND (
             /* Internet publishing & web search portals */
             "subsector"      ILIKE '%internet publishing%'      OR
             "industry_group" ILIKE '%internet publishing%'      OR
             "industry"       ILIKE '%internet publishing%'      OR
             /* Software publishers */
             "subsector"      ILIKE '%software publishers%'      OR
             "industry_group" ILIKE '%software publishers%'      OR
             "industry"       ILIKE '%software publishers%'      OR
             /* Data processing, hosting, and related services */
             "subsector"      ILIKE '%data processing%'          OR
             "industry_group" ILIKE '%data processing%'          OR
             "industry"       ILIKE '%data processing%'          OR
             /* Computer systems design and related services */
             "subsector"      ILIKE '%computer systems design%'  OR
             "industry_group" ILIKE '%computer systems design%'  OR
             "industry"       ILIKE '%computer systems design%'
          )
),
diffs AS (        -- Absolute gaps between Google and BLS
    SELECT 'Asian'    AS race, ABS(g_asian    - b_asian)    AS diff FROM google, bls UNION ALL
    SELECT 'Black'    AS race, ABS(g_black    - b_black)    AS diff FROM google, bls UNION ALL
    SELECT 'Hispanic' AS race, ABS(g_hispanic - b_hispanic) AS diff FROM google, bls UNION ALL
    SELECT 'White'    AS race, ABS(g_white    - b_white)    AS diff FROM google, bls
)
SELECT race,
       diff
FROM diffs
ORDER BY diff DESC NULLS LAST
LIMIT 3;
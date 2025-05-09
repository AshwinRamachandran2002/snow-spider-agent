WITH google AS (
    -- Google 2021 overall-workforce hiring percentages
    SELECT 
        "race_asian"           AS g_asian,
        "race_black"           AS g_black,
        "race_hispanic_latinx" AS g_hispanic_latino,
        "race_white"           AS g_white
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "report_year" = 2021
      AND "workforce"  ILIKE '%overall%'
    LIMIT 1
),
bls AS (
    /* 2021 BLS tech-sector averages  
       Sectors considered:
       - Internet publishing and broadcasting and web search portals
       - Software publishers
       - Data processing, hosting, and related services
       - Computer systems design and related services
    */
    SELECT 
        AVG("percent_asian")                      AS b_asian,
        AVG("percent_black_or_african_american")  AS b_black,
        AVG("percent_hispanic_or_latino")         AS b_hispanic_latino,
        AVG("percent_white")                      AS b_white
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND (
           "sector"        ILIKE '%internet%publishing%'  OR "subsector" ILIKE '%internet%publishing%'  OR "industry_group" ILIKE '%internet%publishing%'  OR "industry" ILIKE '%internet%publishing%'
        OR "sector"        ILIKE '%software%publisher%'   OR "subsector" ILIKE '%software%publisher%'   OR "industry_group" ILIKE '%software%publisher%'   OR "industry" ILIKE '%software%publisher%'
        OR "sector"        ILIKE '%data%process%'         OR "subsector" ILIKE '%data%process%'         OR "industry_group" ILIKE '%data%process%'         OR "industry" ILIKE '%data%process%'
        OR "sector"        ILIKE '%computer%system%design%' OR "subsector" ILIKE '%computer%system%design%' OR "industry_group" ILIKE '%computer%system%design%' OR "industry" ILIKE '%computer%system%design%'
      )
),
diffs AS (
    -- Absolute percentage differences between Google hiring and BLS tech averages
    SELECT 'White'             AS race, ABS(g.g_white          - b.b_white)           AS diff FROM google g, bls b UNION ALL
    SELECT 'Asian'             AS race, ABS(g.g_asian          - b.b_asian)           AS diff FROM google g, bls b UNION ALL
    SELECT 'Black'             AS race, ABS(g.g_black          - b.b_black)           AS diff FROM google g, bls b UNION ALL
    SELECT 'Hispanic/Latino'   AS race, ABS(g.g_hispanic_latino- b.b_hispanic_latino) AS diff FROM google g, bls b
)
SELECT 
    race,
    diff        AS percentage_difference
FROM diffs
ORDER BY diff DESC NULLS LAST
LIMIT 3;
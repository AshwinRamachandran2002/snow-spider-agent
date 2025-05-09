/*  Top three race categories with the largest percentage-point
    differences between Google 2021 “overall” hiring and the
    average 2021 BLS tech-sector workforce composition            */

WITH google AS (           -- Google 2021 overall-hiring percentages
    SELECT
        "race_asian"             AS google_asian ,
        "race_black"             AS google_black ,
        "race_hispanic_latinx"   AS google_hispanic ,
        "race_white"             AS google_white
    FROM GOOGLE_DEI.GOOGLE_DEI."DAR_NON_INTERSECTIONAL_HIRING"
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),
bls AS (              -- Avg. 2021 BLS tech-sector percentages
    SELECT
        AVG("percent_asian")                       AS bls_asian ,
        AVG("percent_black_or_african_american")   AS bls_black ,
        AVG("percent_hispanic_or_latino")          AS bls_hispanic ,
        AVG("percent_white")                       AS bls_white
    FROM GOOGLE_DEI.BLS."CPSAAT18"
    WHERE "year" = 2021
      AND (
            "sector"        ILIKE '%internet publishing%' OR
            "subsector"     ILIKE '%internet publishing%' OR
            "industry_group"ILIKE '%internet publishing%' OR
            "industry"      ILIKE '%internet publishing%' OR
            
            "sector"        ILIKE '%software publishers%'  OR
            "subsector"     ILIKE '%software publishers%'  OR
            "industry_group"ILIKE '%software publishers%'  OR
            "industry"      ILIKE '%software publishers%'  OR
            
            "sector"        ILIKE '%data processing%'      OR
            "subsector"     ILIKE '%data processing%'      OR
            "industry_group"ILIKE '%data processing%'      OR
            "industry"      ILIKE '%data processing%'      OR
            
            "sector"        ILIKE '%computer systems design%' OR
            "subsector"     ILIKE '%computer systems design%' OR
            "industry_group"ILIKE '%computer systems design%' OR
            "industry"      ILIKE '%computer systems design%'
          )
),
combined AS (        -- Build one row per race & compute difference
    SELECT 'Asian'               AS race ,
           g.google_asian        AS google_percentage ,
           b.bls_asian           AS bls_percentage ,
           g.google_asian - b.bls_asian         AS difference
    FROM google g CROSS JOIN bls b
    UNION ALL
    SELECT 'Black'               ,
           g.google_black       ,
           b.bls_black          ,
           g.google_black - b.bls_black
    FROM google g CROSS JOIN bls b
    UNION ALL
    SELECT 'Hispanic or Latino'  ,
           g.google_hispanic    ,
           b.bls_hispanic       ,
           g.google_hispanic - b.bls_hispanic
    FROM google g CROSS JOIN bls b
    UNION ALL
    SELECT 'White'               ,
           g.google_white       ,
           b.bls_white          ,
           g.google_white - b.bls_white
    FROM google g CROSS JOIN bls b
)

SELECT
    race,
    google_percentage,
    bls_percentage,
    difference                       -- positive => Google higher
FROM combined
ORDER BY ABS(difference) DESC NULLS LAST
LIMIT 3;
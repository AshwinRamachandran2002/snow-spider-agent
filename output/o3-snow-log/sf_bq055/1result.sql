/*  Top-3 races with the largest percentage-point gaps between
    Google’s 2021 overall U.S. hiring and the 2021 BLS tech-sector averages
*/
WITH google AS (   -- Google 2021 overall-workforce hiring shares
    SELECT
        "race_white"           AS white ,
        "race_black"           AS black ,
        "race_asian"           AS asian ,
        "race_hispanic_latinx" AS hispanic
    FROM  GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "report_year" = 2021
      AND "workforce"   = 'overall'
),

bls_raw AS (       -- 2021 BLS rows for the four specified tech industries
    SELECT
        "percent_white"                     AS white ,
        "percent_black_or_african_american" AS black ,
        "percent_asian"                     AS asian ,
        "percent_hispanic_or_latino"        AS hispanic
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND (
            /* Internet publishing / web search portals */
            "industry"       ILIKE '%portal%'               OR "industry_group" ILIKE '%portal%'               OR "subsector" ILIKE '%portal%'
         OR /* Software publishers */
            "industry"       ILIKE '%software%publish%'     OR "industry_group" ILIKE '%software%publish%'     OR "subsector" ILIKE '%software%publish%'
         OR /* Data processing, hosting, and related services */
            "industry"       ILIKE '%data%processing%'      OR "industry_group" ILIKE '%data%processing%'      OR "subsector" ILIKE '%data%processing%'
         OR "industry"       ILIKE '%hosting%'              OR "industry_group" ILIKE '%hosting%'              OR "subsector" ILIKE '%hosting%'
         OR /* Computer systems design and related services */
            "industry"       ILIKE '%computer%systems%design%' OR "industry_group" ILIKE '%computer%systems%design%' OR "subsector" ILIKE '%computer%systems%design%'
      )
),

bls AS (           -- average race shares across the selected BLS tech rows
    SELECT
        AVG(white)    AS white ,
        AVG(black)    AS black ,
        AVG(asian)    AS asian ,
        AVG(hispanic) AS hispanic
    FROM bls_raw
),

diff AS (          -- Google minus BLS differences
    SELECT 'white'    AS race , g.white    - b.white    AS difference FROM google g CROSS JOIN bls b
    UNION ALL
    SELECT 'black'    AS race , g.black    - b.black                FROM google g CROSS JOIN bls b
    UNION ALL
    SELECT 'asian'    AS race , g.asian    - b.asian                FROM google g CROSS JOIN bls b
    UNION ALL
    SELECT 'hispanic' AS race , g.hispanic - b.hispanic             FROM google g CROSS JOIN bls b
)

SELECT
    race ,
    difference
FROM diff
ORDER BY ABS(difference) DESC NULLS LAST
LIMIT 3;
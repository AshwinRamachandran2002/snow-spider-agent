/* Top-3 races with the largest percentage gap between Google’s 2021 overall
   hiring mix and the 2021 BLS tech-sector average
*/
WITH google_2021 AS (   -- Google overall hiring mix (2021)
    SELECT
        "race_white"            AS google_white ,
        "race_black"            AS google_black ,
        "race_asian"            AS google_asian ,
        "race_hispanic_latinx"  AS google_hispanic
    FROM  GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
    LIMIT 1
),
bls_tech_2021 AS (      -- BLS tech-sector racial averages (2021)
    SELECT
        AVG("percent_white")                        AS bls_white ,
        AVG("percent_black_or_african_american")    AS bls_black ,
        AVG("percent_asian")                        AS bls_asian ,
        AVG("percent_hispanic_or_latino")           AS bls_hispanic
    FROM  GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND (
           "subsector"      ILIKE 'Internet publishing and broadcasting and web search portals'
        OR "subsector"      ILIKE 'Software publishers'
        OR "subsector"      ILIKE 'Data processing, hosting, and related services'
        OR "industry_group" ILIKE 'Computer systems design and related services'
        OR "industry"       ILIKE 'Computer systems design and related services'
      )
),
diffs AS (              -- Assemble and calculate differences
    SELECT 'white'    AS race , g.google_white    AS google_pct , b.bls_white    AS bls_pct , g.google_white    - b.bls_white    AS diff FROM google_2021 g , bls_tech_2021 b UNION ALL
    SELECT 'black'    AS race , g.google_black    AS google_pct , b.bls_black    AS bls_pct , g.google_black    - b.bls_black    AS diff FROM google_2021 g , bls_tech_2021 b UNION ALL
    SELECT 'asian'    AS race , g.google_asian    AS google_pct , b.bls_asian    AS bls_pct , g.google_asian    - b.bls_asian    AS diff FROM google_2021 g , bls_tech_2021 b UNION ALL
    SELECT 'hispanic' AS race , g.google_hispanic AS google_pct , b.bls_hispanic AS bls_pct , g.google_hispanic - b.bls_hispanic AS diff FROM google_2021 g , bls_tech_2021 b
)
SELECT
    race,
    google_pct,
    bls_pct,
    diff
FROM diffs
ORDER BY ABS(diff) DESC NULLS LAST
LIMIT 3;
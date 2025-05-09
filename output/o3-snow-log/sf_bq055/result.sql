/* Top three races with the largest 2021 Google-vs-BLS hiring percentage gaps
   – Google overall hiring (DAR_NON_INTERSECTIONAL_HIRING, 2021)
   – BLS tech-sector average (CPSAAT18, 2021) restricted to
       • Internet publishing and broadcasting and web search portals
       • Software publishers
       • Data processing, hosting, and related services
       • Computer systems design and related services
*/
WITH bls_tech AS (   -- average 2021 race shares across the four specified tech categories
    SELECT
        AVG("percent_white")                     AS "b_white",
        AVG("percent_black_or_african_american") AS "b_black",
        AVG("percent_asian")                     AS "b_asian",
        AVG("percent_hispanic_or_latino")        AS "b_hispanic"
    FROM "GOOGLE_DEI"."BLS"."CPSAAT18"
    WHERE "year" = 2021
      AND (
              "sector"         ILIKE '%Internet publishing and broadcasting and web search portals%' OR
              "subsector"      ILIKE '%Internet publishing and broadcasting and web search portals%' OR
              "industry_group" ILIKE '%Internet publishing and broadcasting and web search portals%' OR
              "industry"       ILIKE '%Internet publishing and broadcasting and web search portals%' OR

              "sector"         ILIKE '%Software publishers%' OR
              "subsector"      ILIKE '%Software publishers%' OR
              "industry_group" ILIKE '%Software publishers%' OR
              "industry"       ILIKE '%Software publishers%' OR

              "sector"         ILIKE '%Data processing, hosting, and related services%' OR
              "subsector"      ILIKE '%Data processing, hosting, and related services%' OR
              "industry_group" ILIKE '%Data processing, hosting, and related services%' OR
              "industry"       ILIKE '%Data processing, hosting, and related services%' OR

              "sector"         ILIKE '%Computer systems design and related services%' OR
              "subsector"      ILIKE '%Computer systems design and related services%' OR
              "industry_group" ILIKE '%Computer systems design and related services%' OR
              "industry"       ILIKE '%Computer systems design and related services%'
          )
),
google AS (          -- Google overall hiring race shares for 2021
    SELECT
        "race_white"           AS "g_white",
        "race_black"           AS "g_black",
        "race_asian"           AS "g_asian",
        "race_hispanic_latinx" AS "g_hispanic"
    FROM "GOOGLE_DEI"."GOOGLE_DEI"."DAR_NON_INTERSECTIONAL_HIRING"
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
)
SELECT *
FROM (
          SELECT 'White'    AS "race", ABS("g_white"    - "b_white")    AS "difference" FROM google, bls_tech
    UNION ALL
          SELECT 'Black'    AS "race", ABS("g_black"    - "b_black")    AS "difference" FROM google, bls_tech
    UNION ALL
          SELECT 'Asian'    AS "race", ABS("g_asian"    - "b_asian")    AS "difference" FROM google, bls_tech
    UNION ALL
          SELECT 'Hispanic' AS "race", ABS("g_hispanic" - "b_hispanic") AS "difference" FROM google, bls_tech
) diffs
ORDER BY "difference" DESC NULLS LAST
LIMIT 3;
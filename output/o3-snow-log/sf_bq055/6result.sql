/* Top-3 races with the largest 2021 percentage gap
   between Google overall hiring and BLS tech-sector averages */
WITH google_2021 AS (          -- Google overall hiring shares for 2021
    SELECT
        "race_white"            AS white ,
        "race_black"            AS black ,
        "race_asian"            AS asian ,
        "race_hispanic_latinx"  AS hispanic
    FROM  GOOGLE_DEI.GOOGLE_DEI."DAR_NON_INTERSECTIONAL_HIRING"
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),

bls_2021 AS (                  -- Average BLS shares across chosen tech sectors in 2021
    SELECT
        AVG("percent_white")                     AS white ,
        AVG("percent_black_or_african_american") AS black ,
        AVG("percent_asian")                     AS asian ,
        AVG("percent_hispanic_or_latino")        AS hispanic
    FROM  GOOGLE_DEI.BLS."CPSAAT18"
    WHERE "year" = 2021
      AND (
              "industry_group" ILIKE '%computer systems design and related services%'
           OR "subsector"      ILIKE '%software publishers%'
           OR "industry"       ILIKE '%software publishers%'
           OR "subsector"      ILIKE '%internet publishing and broadcasting and web search portals%'
           OR "industry"       ILIKE '%internet publishing and broadcasting and web search portals%'
           OR "subsector"      ILIKE '%data processing, hosting, and related services%'
           OR "industry"       ILIKE '%data processing, hosting, and related services%'
          )
),

diffs AS (                     -- Absolute differences by race
    SELECT 'white'           AS race ,
           ABS(g.white    - b.white   ) AS diff
    FROM   google_2021 g, bls_2021 b

    UNION ALL
    SELECT 'black'           AS race ,
           ABS(g.black    - b.black   ) AS diff
    FROM   google_2021 g, bls_2021 b

    UNION ALL
    SELECT 'asian'           AS race ,
           ABS(g.asian    - b.asian   ) AS diff
    FROM   google_2021 g, bls_2021 b

    UNION ALL
    SELECT 'hispanic_latinx' AS race ,
           ABS(g.hispanic - b.hispanic) AS diff
    FROM   google_2021 g, bls_2021 b
)

SELECT race,
       diff
FROM   diffs
ORDER  BY diff DESC NULLS LAST
LIMIT  3;
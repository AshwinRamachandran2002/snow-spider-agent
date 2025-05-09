/*  “Best‑year” (max EMA, α = 0.2) for every CPC technology area
    at hierarchy level‑5, using the first CPC code per patent        */

WITH RECURSIVE
/*------------------------------------------------------------------*/
cpc_first_code AS (                  -- 1) first CPC code only
    SELECT
        p."publication_number",
        p."filing_date",
        p."application_number",
        f.VALUE:"code"::STRING  AS "cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         , LATERAL FLATTEN(input => p."cpc") f
    WHERE f."INDEX" = 0                         -- first CPC entry
      AND p."application_number" IS NOT NULL
      AND TRIM(p."application_number") <> ''
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" <> 0
),
/*------------------------------------------------------------------*/
counts AS (                           -- 2) yearly counts
    SELECT
        cd."symbol"    AS "cpc_group",
        cd."titleFull" AS "cpc_title",
        TO_NUMBER(SUBSTR(cfc."filing_date"::STRING, 1, 4)) AS "yr",
        COUNT(*)       AS "filings"
    FROM cpc_first_code                 cfc
    JOIN PATENTS.PATENTS.CPC_DEFINITION cd
         ON cd."level" = 5
        AND cfc."cpc_code" ILIKE cd."symbol" || '%'
    GROUP BY cd."symbol",
             cd."titleFull",
             TO_NUMBER(SUBSTR(cfc."filing_date"::STRING, 1, 4))
),
/*------------------------------------------------------------------*/
ordered_counts AS (                   -- 3) order years within group
    SELECT
        "cpc_group",
        "cpc_title",
        "yr",
        "filings",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group" ORDER BY "yr") AS rn
    FROM counts
),
/*------------------------------------------------------------------*/
ema_recursive AS (                    -- 4) exponential moving average
    -- seed row (first year for each group)
    SELECT
        "cpc_group",
        "cpc_title",
        "yr",
        "filings",
        CAST("filings" AS FLOAT) AS ema,
        rn
    FROM ordered_counts
    WHERE rn = 1

    UNION ALL

    -- recursive step
    SELECT
        oc."cpc_group",
        oc."cpc_title",
        oc."yr",
        oc."filings",
        0.2 * oc."filings" + 0.8 * er.ema AS ema,
        oc.rn
    FROM ema_recursive  er
    JOIN ordered_counts oc
          ON oc."cpc_group" = er."cpc_group"
         AND oc.rn         = er.rn + 1
),
/*------------------------------------------------------------------*/
best_year AS (                        -- 5) locate year of max EMA
    SELECT
        "cpc_group",
        "cpc_title",
        "yr"  AS "best_year",
        ema   AS "max_ema",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                           ORDER BY ema DESC, "yr" ASC) AS rnk
    FROM ema_recursive
)
/*------------------------------------------------------------------*/
SELECT
    "cpc_group",
    "cpc_title",
    "best_year",
    "max_ema"
FROM best_year
WHERE rnk = 1
ORDER BY "cpc_group";
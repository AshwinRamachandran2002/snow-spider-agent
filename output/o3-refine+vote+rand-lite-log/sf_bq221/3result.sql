/*  Highest exponential‑moving‑average (α = 0.2) filing‑year
    for every CPC “main group” (level‑5, i.e.   xxxxN/00 )           */

WITH RECURSIVE
/*------------------------------------------------------------------*
 | 1.  Take only the first CPC code of every publication that        |
 |     possesses a filing date.                                      |
 *------------------------------------------------------------------*/
first_cpc AS (         
    SELECT
        p."publication_number",
        p."filing_date",
        fl.value:"code"::STRING                            AS "cpc_code",
        ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                           ORDER BY fl."INDEX")            AS seq_in_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p ,
         LATERAL FLATTEN ( INPUT => p."cpc" ) fl
    WHERE p."filing_date" IS NOT NULL
),
base AS (
    SELECT
        "publication_number",
        "filing_date",
        "cpc_code"
    FROM first_cpc
    WHERE seq_in_pub = 1                  -- keep first CPC only
          AND "cpc_code" IS NOT NULL
),
/*------------------------------------------------------------------*
 | 2.  Derive the CPC main‑group symbol (level‑5) by converting      |
 |     any code like H04L9/08   ->  H04L9/00                         |
 *------------------------------------------------------------------*/
main_group AS (
    SELECT
        "publication_number",
        "filing_date",
        REGEXP_REPLACE("cpc_code", '/[^/]+$', '/00')       AS "cpc_group"
    FROM base
),
/*------------------------------------------------------------------*
 | 3.  Attach a readable CPC title (if present in definition table). |
 *------------------------------------------------------------------*/
with_title AS (
    SELECT
        m."publication_number",
        m."filing_date",
        m."cpc_group",
        COALESCE(d."titleFull", m."cpc_group")             AS "full_cpc_title"
    FROM main_group m
    LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
           ON d."symbol" = m."cpc_group"
),
/*------------------------------------------------------------------*
 | 4.  Yearly filing counts per CPC main‑group.                      |
 *------------------------------------------------------------------*/
per_year AS (
    SELECT
        "cpc_group",
        "full_cpc_title",
        FLOOR("filing_date" / 10000)::INT                  AS "year",
        COUNT(DISTINCT "publication_number")               AS "filings"
    FROM with_title
    GROUP BY "cpc_group", "full_cpc_title", "year"
),
/*------------------------------------------------------------------*
 | 5.  Order the years inside every CPC group.                       |
 *------------------------------------------------------------------*/
ordered AS (
    SELECT
        "cpc_group",
        "full_cpc_title",
        "year",
        "filings",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                           ORDER BY "year")                AS "rn"
    FROM per_year
),
/*------------------------------------------------------------------*
 | 6.  Recursive EMA:                                               |
 |       ema₁ = filings₁                                            |
 |       emaₙ = 0.2·filingsₙ + 0.8·ema₍ₙ₋₁₎                         |
 *------------------------------------------------------------------*/
ema_recursive AS (
    -- anchor (first year in each group)
    SELECT
        o."cpc_group",
        o."full_cpc_title",
        o."year",
        o."filings",
        CAST(o."filings" AS DOUBLE)                        AS "ema",
        o."rn"
    FROM ordered o
    WHERE o."rn" = 1

    UNION ALL

    -- recursive step
    SELECT
        o."cpc_group",
        o."full_cpc_title",
        o."year",
        o."filings",
        0.2 * o."filings" + 0.8 * r."ema"                 AS "ema",
        o."rn"
    FROM ordered       o
    JOIN ema_recursive r
      ON o."cpc_group" = r."cpc_group"
     AND o."rn"        = r."rn" + 1
),
/*------------------------------------------------------------------*
 | 7.  Pick the year with the highest EMA for every CPC group.       |
 *------------------------------------------------------------------*/
best_year AS (
    SELECT
        "cpc_group",
        "full_cpc_title",
        "year"                                             AS "best_year",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                           ORDER BY "ema" DESC,
                                    "year" ASC)            AS rk
    FROM ema_recursive
)
/*------------------------------------------------------------------*
 | 8.  Final result.                                                |
 *------------------------------------------------------------------*/
SELECT
    "cpc_group",
    "full_cpc_title",
    "best_year"
FROM best_year
WHERE rk = 1
ORDER BY "cpc_group";
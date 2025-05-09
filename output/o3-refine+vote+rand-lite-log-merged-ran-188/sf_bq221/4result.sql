/*  Highest-EMA year (α = 0.20) for every level-5 CPC group            */
WITH RECURSIVE
/* ------------------------------------------------------------------ */
/* 1. First CPC symbol + filing year                                   */
first_cpc AS (
    SELECT
        REGEXP_SUBSTR(c.value:"code"::STRING , '^[A-Z][0-9]{2}[A-Z]') AS "symbol",
        FLOOR(p."filing_date" / 10000)                                AS "year"
    FROM PATENTS.PATENTS."PUBLICATIONS"  p,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE c.index              = 0
      AND p."application_number" IS NOT NULL
      AND p."filing_date"        IS NOT NULL
      AND c.value:"code"         IS NOT NULL
),
/* ------------------------------------------------------------------ */
/* 2. Yearly filing counts                                             */
yearly_counts AS (
    SELECT
        "symbol",
        "year",
        COUNT(*) AS "filing_count"
    FROM first_cpc
    GROUP BY "symbol", "year"
),
/* ------------------------------------------------------------------ */
/* 3. Add running index per CPC                                        */
ordered_counts AS (
    SELECT
        "symbol",
        "year",
        "filing_count",
        ROW_NUMBER() OVER (PARTITION BY "symbol" ORDER BY "year") AS "rn"
    FROM yearly_counts
),
/* ------------------------------------------------------------------ */
/* 4. Recursive EMA computation (α = 0.20)                             */
ema_calc AS (
    /* seed rows (earliest year per CPC)                               */
    SELECT
        "symbol",
        "year",
        "filing_count",
        "rn",
        CAST("filing_count" AS FLOAT)            AS "ema"
    FROM ordered_counts
    WHERE "rn" = 1

    UNION ALL

    /* recursive step                                                  */
    SELECT
        o."symbol",
        o."year",
        o."filing_count",
        o."rn",
        0.20 * o."filing_count" + 0.80 * e."ema" AS "ema"
    FROM ema_calc       e
    JOIN ordered_counts o
         ON o."symbol" = e."symbol"
        AND o."rn"     = e."rn" + 1
),
/* ------------------------------------------------------------------ */
/* 5. Year with maximum EMA per CPC                                    */
best_rows AS (
    SELECT
        "symbol",
        "year" AS "best_year",
        "ema"  AS "highest_ema",
        ROW_NUMBER() OVER (PARTITION BY "symbol" ORDER BY "ema" DESC) AS "rnk"
    FROM ema_calc
),
best_year AS (
    SELECT
        "symbol",
        "best_year",
        "highest_ema"
    FROM best_rows
    WHERE "rnk" = 1
)
/* ------------------------------------------------------------------ */
/* 6. Attach CPC title and output                                      */
SELECT
    b."symbol"      AS "cpc_symbol",
    d."titleFull"   AS "cpc_title",
    b."best_year",
    ROUND(b."highest_ema", 4) AS "highest_ema"
FROM best_year b
LEFT JOIN PATENTS.PATENTS."CPC_DEFINITION" d
       ON d."symbol" = b."symbol"
      AND d."level"  = 5
ORDER BY b."highest_ema" DESC NULLS LAST;
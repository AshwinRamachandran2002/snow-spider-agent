/*  Highest-EMA (α = 0.2) filing year for each CPC 5-character technology group */

WITH RECURSIVE

/* 1 ─ keep only first-listed CPC code and extract filing year */
first_cpc AS (
    SELECT
        REGEXP_SUBSTR(f.value:"code"::STRING , '^[A-Z][0-9]{2}[A-Z][0-9]')   AS "cpc_group_5",
        FLOOR(p."filing_date" / 10000)                                       AS "filing_year"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE p."application_number" <> ''
      AND p."filing_date"        IS NOT NULL
      AND f.value:"first"::BOOLEAN = TRUE
),

/* 2 ─ yearly filing counts per CPC group */
yearly AS (
    SELECT
        "cpc_group_5",
        "filing_year",
        COUNT(*) AS "yearly_filings"
    FROM first_cpc
    GROUP BY "cpc_group_5", "filing_year"
),

/* 3 ─ chronological index within each group */
ordered AS (
    SELECT
        y."cpc_group_5",
        y."filing_year",
        y."yearly_filings",
        ROW_NUMBER() OVER (PARTITION BY y."cpc_group_5"
                           ORDER BY y."filing_year") AS "rn"
    FROM yearly y
),

/* 4 ─ recursive EMA calculation (α = 0.2) */
ema_rec ("cpc_group_5", "rn", "filing_year", "ema_alpha_0_2") AS (

    /* anchor: first year of each group */
    SELECT
        o."cpc_group_5",
        o."rn",
        o."filing_year",
        o."yearly_filings" * 0.2
    FROM ordered o
    WHERE o."rn" = 1

    UNION ALL

    /* recursion */
    SELECT
        o."cpc_group_5",
        o."rn",
        o."filing_year",
        0.2 * o."yearly_filings" + 0.8 * e."ema_alpha_0_2"
    FROM ema_rec e
    JOIN ordered o
      ON o."cpc_group_5" = e."cpc_group_5"
     AND o."rn"          = e."rn" + 1
),

/* 5 ─ highest-EMA year per group */
best AS (
    SELECT
        "cpc_group_5",
        "filing_year"  AS "best_year",
        "ema_alpha_0_2" AS "highest_ema",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group_5"
                           ORDER BY "ema_alpha_0_2" DESC) AS "rk"
    FROM ema_rec
)

SELECT
    b."cpc_group_5",
    FIRST_VALUE(d."titleFull") OVER (PARTITION BY b."cpc_group_5"
                                     ORDER BY d."level" NULLS LAST) AS "cpc_full_title",
    b."best_year",
    ROUND(b."highest_ema", 4)                                       AS "highest_ema"
FROM best b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON  d."symbol" = b."cpc_group_5"
        OR d."symbol" LIKE b."cpc_group_5" || '/%'
WHERE b."rk" = 1
ORDER BY b."highest_ema" DESC NULLS LAST;
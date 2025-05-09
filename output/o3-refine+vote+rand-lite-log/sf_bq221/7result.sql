/* -------------------------------------------------------------
   Identify, for every level‑5 CPC group, the year in which the
   exponential moving average (α = 0.2) of annual patent filings
   is highest.
--------------------------------------------------------------*/
WITH RECURSIVE
/* --- 1. First CPC code per publication --------------------- */
pub_first_cpc AS (
    SELECT
        p."publication_number",
        p."filing_date",
        p."application_number",
        UPPER(f.value:"code"::STRING)     AS cpc_code        -- first CPC code
    FROM PATENTS.PATENTS."PUBLICATIONS" p,
         LATERAL FLATTEN(INPUT => p."cpc") f
    WHERE f.index = 0                               -- only the first CPC entry
      AND p."filing_date"        IS NOT NULL
      AND p."application_number" IS NOT NULL
      AND p."application_number" <> ''
),
/* --- 2. Level‑5 CPC symbols ------------------------------- */
level5 AS (
    SELECT
        UPPER("symbol") AS symbol,
        "titleFull"
    FROM PATENTS.PATENTS."CPC_DEFINITION"
    WHERE "level" = 5
),
/* --- 3. Map publication to its level‑5 CPC ---------------- */
mapped AS (
    SELECT
        pf."publication_number",
        pf."filing_date",
        l.symbol          AS cpc_group,
        l."titleFull"
    FROM pub_first_cpc pf
    JOIN level5 l
      ON pf.cpc_code LIKE l.symbol || '%'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pf."publication_number"
                               ORDER BY LENGTH(l.symbol) DESC) = 1
),
/* --- 4. Yearly filing counts per CPC group ---------------- */
year_counts AS (
    SELECT
        cpc_group,
        "titleFull",
        CAST(FLOOR("filing_date" / 10000) AS INT) AS filing_year,  -- YYYY
        COUNT(*)                                AS filings
    FROM mapped
    GROUP BY cpc_group, "titleFull", filing_year
),
/* --- 5. Order years inside each CPC group ----------------- */
ordered AS (
    SELECT
        cpc_group,
        "titleFull",
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY filing_year) AS rn
    FROM year_counts
),
/* --- 6. Recursive EMA computation (α = 0.2) --------------- */
ema_calc AS (
    /* anchor: first year per CPC */
    SELECT
        cpc_group,
        "titleFull",
        filing_year,
        filings,
        filings                          AS ema,   -- EMA_0 = count_0
        rn
    FROM ordered
    WHERE rn = 1

    UNION ALL

    /* recursion: EMA_t = 0.2*count_t + 0.8*EMA_{t‑1} */
    SELECT
        o.cpc_group,
        o."titleFull",
        o.filing_year,
        o.filings,
        0.2 * o.filings + 0.8 * e.ema    AS ema,
        o.rn
    FROM ema_calc e
    JOIN ordered o
      ON o.cpc_group = e.cpc_group
     AND o.rn       = e.rn + 1
),
/* --- 7. Pick best year (highest EMA) per CPC -------------- */
best_years AS (
    SELECT
        cpc_group,
        "titleFull",
        filing_year       AS best_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY ema DESC, filing_year ASC) AS rk
    FROM ema_calc
)
SELECT
    cpc_group            AS "CPC_CODE_LEVEL5",
    "titleFull"          AS "CPC_TITLE",
    best_year            AS "BEST_YEAR",
    ROUND(ema, 4)        AS "MAX_EMA"
FROM best_years
WHERE rk = 1
ORDER BY "MAX_EMA" DESC NULLS LAST, "CPC_CODE_LEVEL5";
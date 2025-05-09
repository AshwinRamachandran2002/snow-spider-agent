/*  -----------------------------------------------------------
    Best‑year (highest EMA, α = 0.2) for every CPC level‑5 group
    ----------------------------------------------------------- */
WITH first_cpc AS (   /* keep only the very first CPC code per publication */
    SELECT
        CAST(p."filing_date" / 10000 AS INT)                     AS "year",
        LEFT(f.value:"code"::STRING, 4)                          AS "cpc_group"   -- level‑5 subclass (e.g. H04L)
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") f
    WHERE p."filing_date" IS NOT NULL
      AND COALESCE(p."application_number", '') <> ''
    QUALIFY ROW_NUMBER() OVER (PARTITION BY p."publication_number"
                               ORDER BY f.index) = 1
),
year_counts AS (       /* annual patent‑filing counts per CPC group */
    SELECT
        "cpc_group",
        "year",
        COUNT(*) AS "patent_filings"
    FROM first_cpc
    GROUP BY "cpc_group", "year"
),
ordered AS (           /* assign ascending rank within each CPC group */
    SELECT
        "cpc_group",
        "year",
        "patent_filings",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group" ORDER BY "year") AS rn
    FROM year_counts
),
ema_pre AS (           /* prepare cumulative weighted sums (β = 0.8)  */
    SELECT
        "cpc_group",
        "year",
        "patent_filings",
        /* weight for this row: β^{‑(rn‑1)}  (β = 1‑α = 0.8) */
        POWER(0.8, -(rn - 1))                                      AS w,
        SUM("patent_filings" * POWER(0.8, -(rn - 1)))
              OVER (PARTITION BY "cpc_group"
                    ORDER BY rn
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS num,
        SUM(POWER(0.8, -(rn - 1)))
              OVER (PARTITION BY "cpc_group"
                    ORDER BY rn
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS den
    FROM ordered
),
ema_calc AS (          /* exponential moving average α = 0.2 */
    SELECT
        "cpc_group",
        "year",
        "patent_filings",
        num / den AS "ema_0_2"
    FROM ema_pre
),
best_year AS (         /* pick the year with the highest EMA for each group */
    SELECT DISTINCT
        "cpc_group",
        FIRST_VALUE("year") OVER (PARTITION BY "cpc_group"
                                  ORDER BY "ema_0_2" DESC, "year") AS "best_year",
        MAX("ema_0_2")       OVER (PARTITION BY "cpc_group")       AS "max_ema"
    FROM ema_calc
)
/* ------------------------------------------------------------
   Final result: CPC symbol, full CPC title, best year, max EMA
   ------------------------------------------------------------ */
SELECT
    b."cpc_group"                              AS "cpc_symbol",
    d."titleFull"                              AS "cpc_title",
    b."best_year",
    b."max_ema"
FROM best_year b
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = b."cpc_group"               /* link to definition table */
WHERE d."level" = 5                           /* only level‑5 technology areas */
ORDER BY b."max_ema" DESC NULLS LAST,         /* most significant EMA first */
         b."cpc_group";
WITH RECURSIVE
/*───────────────── 1) yearly patent-filing counts per German CPC-4 ─────────────────*/
yearly AS (
    SELECT
        SUBSTR(c.value:"code"::STRING,1,4)               AS "cpc_group",
        FLOOR(t."filing_date"/10000)                     AS "filing_year",
        COUNT(DISTINCT t."publication_number")           AS "filings",
        ROW_NUMBER() OVER(
            PARTITION BY SUBSTR(c.value:"code"::STRING,1,4)
            ORDER BY FLOOR(t."filing_date"/10000)
        )                                               AS "rn"
    FROM   PATENTS.PATENTS.PUBLICATIONS t,
           LATERAL FLATTEN(input => t."cpc") c
    WHERE  t."country_code" = 'DE'
      AND  t."grant_date"  BETWEEN 20161201 AND 20161231   -- granted in Dec-2016
      AND  t."filing_date" IS NOT NULL
    GROUP  BY 1,2
),
/*───────────────── 2) recursive EMA (α = 0.1) calculation ─────────────────────────*/
ema_rec AS (
    /* seed with first year per group */
    SELECT  "cpc_group","filing_year","filings","rn",
            "filings"::FLOAT                              AS "ema"
    FROM    yearly
    WHERE   "rn" = 1
    UNION ALL
    /* recursive step */
    SELECT  y."cpc_group",
            y."filing_year",
            y."filings",
            y."rn",
            0.1*y."filings" + 0.9*e."ema"                 AS "ema"
    FROM    ema_rec e
    JOIN    yearly   y
           ON y."cpc_group" = e."cpc_group"
          AND y."rn"        = e."rn" + 1
),
/*───────────────── 3) select peak-EMA year per CPC group ──────────────────────────*/
best_year AS (
    SELECT  "cpc_group",
            "filing_year"                                 AS "best_year",
            "ema",
            ROW_NUMBER() OVER(
                PARTITION BY "cpc_group"
                ORDER BY "ema" DESC, "filing_year"
            ) AS "rk"
    FROM    ema_rec
)
/*───────────────── 4) final output with CPC titles ────────────────────────────────*/
SELECT
    b."cpc_group",
    d."titleFull"       AS "cpc_title",
    b."best_year",
    b."ema"
FROM        best_year b
LEFT JOIN   PATENTS.PATENTS.CPC_DEFINITION d
       ON   d."symbol" = b."cpc_group"
WHERE       b."rk" = 1
ORDER BY    b."ema" DESC NULLS LAST;
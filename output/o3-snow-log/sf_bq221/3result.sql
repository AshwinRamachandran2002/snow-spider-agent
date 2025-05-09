/* ---------------------------------------------------------------------------
   Identify the CPC subclasses (level-5 symbols) that reach the highest
   exponential moving average (α = 0.2) of yearly patent-filing counts.
   -------------------------------------------------------------------------*/
WITH first_cpc AS (           /* first CPC code per publication */
    SELECT
        p."publication_number",
        /* subclass = one letter, two digits, one letter  (level-5 symbol) */
        REGEXP_SUBSTR(
            SPLIT_PART(c.value:"code"::STRING, '/', 1),
            '^[A-Z][0-9]{2}[A-Z]'
        )                                   AS "subclass",
        FLOOR(p."filing_date" / 10000)      AS "year",
        ROW_NUMBER() OVER (
            PARTITION BY p."publication_number"
            ORDER BY c.index
        )                                   AS "rn"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE p."application_number" IS NOT NULL
      AND p."filing_date"        > 0
),
counts_by_year AS (           /* yearly counts per subclass */
    SELECT
        "subclass"  AS "cpc_group",
        "year",
        COUNT(*)     AS "filings"
    FROM first_cpc
    WHERE "rn" = 1
      AND "subclass" IS NOT NULL
    GROUP BY "subclass", "year"
),
ema AS (                      /* exponential moving average, α = 0.2 */
    SELECT
        y1."cpc_group",
        y1."year",
        SUM(
            y2."filings" * POWER(0.8, y1."year" - y2."year")
        )                     AS "ema_val"
    FROM counts_by_year y1
    JOIN counts_by_year y2
      ON y1."cpc_group" = y2."cpc_group"
     AND y2."year"      <= y1."year"
    GROUP BY y1."cpc_group", y1."year"
),
best_per_group AS (           /* year with the maximum EMA per subclass */
    SELECT
        "cpc_group",
        "year"    AS "best_year",
        "ema_val" AS "max_ema",
        ROW_NUMBER() OVER (
            PARTITION BY "cpc_group"
            ORDER BY "ema_val" DESC, "year" ASC
        )                     AS "rn"
    FROM ema
)
SELECT
    COALESCE(d."symbol", b."cpc_group")      AS "cpc_group",
    d."titleFull"                           AS "cpc_title",
    b."best_year",
    b."max_ema"
FROM best_per_group b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b."cpc_group"
      AND d."level"  = 5
WHERE b."rn" = 1
ORDER BY b."max_ema" DESC NULLS LAST;
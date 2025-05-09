/* ============================================================
   CPC technology areas (level-4 groups) that reach their
   highest exponential moving average (α = 0.1) of German
   patent-family filings, among patents that were GRANTED
   in December-2016.
   ============================================================ */
WITH RECURSIVE
/* ------------------------------------------------------------
   1)  German publications whose GRANT was published
       during December-2016 (exclude application kind “A…”)
-------------------------------------------------------------*/
dec16_de_grants AS (
    SELECT
        p."filing_date",          -- yyyymmdd, numeric
        p."cpc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'DE'
      AND p."publication_date" BETWEEN 20161201 AND 20161231
      AND UPPER(SUBSTR(p."kind_code",1,1)) <> 'A'   -- granted kinds (B,C,T…)
      AND p."cpc" IS NOT NULL
      AND p."filing_date" > 0
),
/* ------------------------------------------------------------
   2)  explode CPC codes, keep only the LEVEL-4 “main group”
       (e.g.  H04L9/0838 → H04L9/08)
-------------------------------------------------------------*/
cpc_lvl4 AS (
    SELECT
        TRY_TO_NUMBER(SUBSTR(TO_CHAR(d."filing_date"),1,4))     AS filing_year,
        REGEXP_REPLACE( c.value:"code"::STRING
                      , '^([^/]+/\\d{2}).*'                      -- keep 2 digits
                      , '\\1')                                   AS cpc_group
    FROM dec16_de_grants d,
         LATERAL FLATTEN(INPUT => d."cpc")  c
    WHERE c.value:"code" IS NOT NULL
),
/* ------------------------------------------------------------
   3)  yearly filing counts for every CPC level-4 group
-------------------------------------------------------------*/
year_counts AS (
    SELECT
        cpc_group,
        filing_year,
        COUNT(*) AS filings
    FROM cpc_lvl4
    WHERE filing_year IS NOT NULL
    GROUP BY cpc_group, filing_year
),
/* ------------------------------------------------------------
   4)  order rows inside each CPC group
-------------------------------------------------------------*/
ordered AS (
    SELECT
        cpc_group,
        filing_year,
        filings,
        ROW_NUMBER() OVER (PARTITION BY cpc_group ORDER BY filing_year) AS rn
    FROM year_counts
),
/* ------------------------------------------------------------
   5)  recursive EMA   EMA₁ = count₁
                       EMAₙ = 0.1·countₙ + 0.9·EMAₙ₋₁
-------------------------------------------------------------*/
ema AS (
    /* anchor */
    SELECT
        cpc_group,
        filing_year,
        filings,
        rn,
        filings::FLOAT AS ema
    FROM ordered
    WHERE rn = 1

    UNION ALL

    /* step */
    SELECT
        o.cpc_group,
        o.filing_year,
        o.filings,
        o.rn,
        0.1 * o.filings + 0.9 * e.ema AS ema
    FROM ordered o
    JOIN ema     e
      ON o.cpc_group = e.cpc_group
     AND o.rn       = e.rn + 1
),
/* ------------------------------------------------------------
   6)  pick the year with the highest EMA for every group
-------------------------------------------------------------*/
peak AS (
    SELECT
        cpc_group,
        filing_year  AS peak_year,
        ema,
        ROW_NUMBER() OVER (PARTITION BY cpc_group
                           ORDER BY ema DESC, filing_year) AS rnk
    FROM ema
)
SELECT
    d."titleFull"     AS full_title,
    p.cpc_group,
    p.peak_year
FROM peak p
JOIN PATENTS.PATENTS.CPC_DEFINITION d
  ON d."symbol" = p.cpc_group            -- exact level-4 symbol
WHERE p.rnk = 1
ORDER BY p.peak_year, p.cpc_group;
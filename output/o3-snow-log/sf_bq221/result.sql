/*--------------------------------------------------------------
  1.  Get the FIRST CPC code for every patent that has
      – a valid filing date (>0) and
      – a non-empty application number.
----------------------------------------------------------------*/
WITH first_cpc AS (  
    SELECT  
        p."publication_number",
        TO_NUMBER(SUBSTR(p."filing_date"::STRING,1,4))        AS "filing_year",
        f.value:"code"::STRING                                AS "first_cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS              p,
         LATERAL FLATTEN(input => p."cpc")         f
    WHERE p."application_number" IS NOT NULL
      AND p."application_number" <> ''
      AND p."filing_date"        > 0
    QUALIFY ROW_NUMBER() 
            OVER (PARTITION BY p."publication_number" ORDER BY f.index) = 1
),

/*--------------------------------------------------------------
  2.  Map every first CPC code to its LEVEL-5 CPC group
----------------------------------------------------------------*/
level5_map AS (
    SELECT 
        d."symbol"    AS "level5_symbol",
        d."titleFull" AS "level5_title"
    FROM PATENTS.PATENTS.CPC_DEFINITION d
    WHERE d."level" = 5
),

/*--------------------------------------------------------------
  3.  Count patent filings per year for every level-5 CPC group
----------------------------------------------------------------*/
yearly_counts AS (
    SELECT
        lm."level5_symbol",
        lm."level5_title",
        fc."filing_year"                       AS "year",
        COUNT(*)                               AS "filings"
    FROM first_cpc  fc
    JOIN level5_map lm
         ON lm."level5_symbol" = SUBSTR(fc."first_cpc_code",1,4)
    WHERE fc."filing_year" IS NOT NULL
    GROUP BY lm."level5_symbol", lm."level5_title", fc."filing_year"
),

/*--------------------------------------------------------------
  4.  Give each (group, year) a running index to drive recursion
----------------------------------------------------------------*/
ranked_years AS (
    SELECT
        yc.*,
        ROW_NUMBER() OVER (PARTITION BY yc."level5_symbol"
                           ORDER BY yc."year")  AS "rn"
    FROM yearly_counts yc
),

/*--------------------------------------------------------------
  5.  Compute the Exponential Moving Average (α = 0.2)
      EMAₜ = 0.2 · filingsₜ  + 0.8 · EMAₜ₋₁
----------------------------------------------------------------*/
EMA_RECURSIVE AS (
    -- Base case : first year of each CPC group
    SELECT
        ry."level5_symbol",
        ry."level5_title",
        ry."year",
        ry."filings",
        ry."filings"::FLOAT                      AS "ema",
        ry."rn"
    FROM ranked_years ry
    WHERE ry."rn" = 1
    
    UNION ALL
    
    -- Recursive step : all subsequent years
    SELECT
        nxt."level5_symbol",
        nxt."level5_title",
        nxt."year",
        nxt."filings",
        0.2 * nxt."filings" + 0.8 * prv."ema"    AS "ema",
        nxt."rn"
    FROM EMA_RECURSIVE  prv
    JOIN ranked_years   nxt
      ON nxt."level5_symbol" = prv."level5_symbol"
     AND nxt."rn"        = prv."rn" + 1
),

/*--------------------------------------------------------------
  6.  Pick the year where each CPC group hits its highest EMA
----------------------------------------------------------------*/
best_per_group AS (
    SELECT
        e."level5_symbol",
        e."level5_title",
        e."year"       AS "best_year",
        e."ema"        AS "highest_ema",
        ROW_NUMBER() OVER (PARTITION BY e."level5_symbol"
                           ORDER BY e."ema" DESC) AS "rk"
    FROM EMA_RECURSIVE e
)

/*--------------------------------------------------------------
  7.  Final result
----------------------------------------------------------------*/
SELECT
    b."level5_symbol"       AS "cpc_group",
    b."level5_title"        AS "cpc_title",
    b."best_year",
    ROUND(b."highest_ema",4) AS "highest_ema"
FROM best_per_group b
WHERE b."rk" = 1
ORDER BY b."highest_ema" DESC NULLS LAST;
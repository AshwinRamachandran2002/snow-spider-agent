/*  -------------------------------------------------------
    1) pick German patents granted in December‑2016
    2) explode their CPC codes and keep the 4‑character group
    3) count filings by (CPC group , filing‑year)
    4) compute the exponential moving average (α = 0.1) per group
       with a recursive CTE
    5) keep the year that shows the highest EMA for every group
    6) add the CPC full title (level‑4) from CPC_DEFINITION
--------------------------------------------------------- */
WITH de_dec2016 AS (   -- 1 + 2
    SELECT
        p."filing_date",
        UPPER(SUBSTR(f.value:"code"::string , 1 , 4))  AS "cpc_group"
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN (INPUT => p."cpc") f
    WHERE p."country_code" = 'DE'
      AND p."grant_date"    BETWEEN 20161201 AND 20161231
      AND p."cpc"           IS NOT NULL
      AND p."filing_date"   > 0
),
yearly AS (            -- 3
    SELECT
        "cpc_group",
        YEAR(TO_DATE("filing_date"::string,'YYYYMMDD'))  AS "filing_year",
        COUNT(*)                                          AS "filings"
    FROM de_dec2016
    GROUP BY "cpc_group","filing_year"
),
ordered AS (
    SELECT
        "cpc_group",
        "filing_year",
        "filings",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group" ORDER BY "filing_year") AS "rn"
    FROM yearly
),
/* 4) recursive EMA :  EMA_t = 0.1·x_t + 0.9·EMA_{t‑1}  */
ema_recursive AS (
    WITH RECURSIVE r AS (
        SELECT
            "cpc_group",
            "filing_year",
            "filings",
            "rn",
            CAST("filings" AS FLOAT)                          AS "ema"
        FROM ordered
        WHERE "rn" = 1
        UNION ALL
        SELECT
            o."cpc_group",
            o."filing_year",
            o."filings",
            o."rn",
            0.1 * o."filings" + 0.9 * r."ema"                AS "ema"
        FROM ordered o
        JOIN r
          ON o."cpc_group" = r."cpc_group"
         AND o."rn"        = r."rn" + 1
    )
    SELECT * FROM r
),
best_year AS (        -- 5
    SELECT
        "cpc_group",
        "filing_year"                 AS "best_year",
        "ema",
        ROW_NUMBER() OVER (PARTITION BY "cpc_group"
                           ORDER BY "ema" DESC , "filing_year") AS "rank_in_grp"
    FROM ema_recursive
)
SELECT                 -- 6  final result
    d."titleFull"      AS "full_title",
    b."cpc_group",
    b."best_year"
FROM best_year b
JOIN PATENTS.PATENTS.CPC_DEFINITION d
      ON d."symbol" = b."cpc_group"
WHERE b."rank_in_grp" = 1            -- keep highest EMA per group
ORDER BY b."ema" DESC NULLS LAST;    -- biggest EMA on top
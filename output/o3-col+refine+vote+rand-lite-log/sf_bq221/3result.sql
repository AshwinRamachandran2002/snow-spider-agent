/*  Identify, for every CPC level-5 group, the calendar year in which the
    exponential-moving-average (α = 0.20) of patent filings reached its
    maximum.  Only the FIRST CPC code per publication is considered, and
    publications must have a non-empty application number and a valid
    filing-date.  The query returns the CPC symbol, its full title, the
    “best” year and the corresponding EMA value.                                    */

WITH first_cpc AS (        -- keep only the 1st CPC code of each publication
    SELECT
        REGEXP_SUBSTR(
            c.value:"code"::STRING,
            '^[A-Z][0-9]{2}[A-Z][0-9]/[0-9]{2}'
        )                                   AS "cpc_lvl5",
        FLOOR(p."filing_date" / 10000)      AS "year"
    FROM PATENTS.PATENTS.PUBLICATIONS  p ,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE c.index = 0
      AND p."application_number" IS NOT NULL
      AND p."filing_date" > 0
      AND REGEXP_SUBSTR(
              c.value:"code"::STRING,
              '^[A-Z][0-9]{2}[A-Z][0-9]/[0-9]{2}'
          ) IS NOT NULL
),
yearly_cnt AS (            -- patent-count per CPC×year
    SELECT
        "cpc_lvl5",
        "year",
        COUNT(*) AS "pub_cnt"
    FROM first_cpc
    GROUP BY 1, 2
),
ordered AS (               -- add row numbers (oldest-to-newest)
    SELECT
        y.*,
        ROW_NUMBER() OVER (PARTITION BY "cpc_lvl5" ORDER BY "year") AS rn
    FROM yearly_cnt y
),
max_rn AS (                -- highest row number per CPC (needed for weights)
    SELECT
        "cpc_lvl5",
        MAX(rn) AS max_rn
    FROM ordered
    GROUP BY 1
),
ema AS (                   -- EMA(α=0.2) for every CPC×year
    SELECT
        o."cpc_lvl5",
        o."year",
        o."pub_cnt",
        SUM( 0.2 * o."pub_cnt" * POWER(0.8, m.max_rn - o.rn) )
              OVER (PARTITION BY o."cpc_lvl5"
                    ORDER BY o.rn
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS "ema_0_2"
    FROM ordered o
    JOIN max_rn  m  ON m."cpc_lvl5" = o."cpc_lvl5"
),
best_year AS (             -- keep the year with the highest EMA per CPC
    SELECT
        e."cpc_lvl5",
        e."year"     AS "best_year",
        e."ema_0_2",
        ROW_NUMBER() OVER (PARTITION BY e."cpc_lvl5"
                           ORDER BY e."ema_0_2" DESC) AS rk
    FROM ema e
)
SELECT
    b."cpc_lvl5",
    d."titleFull"       AS "cpc_full_title",
    b."best_year",
    b."ema_0_2"
FROM best_year b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b."cpc_lvl5"
WHERE b.rk = 1                 -- one row (the “best year”) per CPC group
ORDER BY b."cpc_lvl5";
/*  -------------------------------------------------------------
    Identify CPC technology areas (level-5 groups) that exhibit
    the highest exponential moving average (α = 0.2) of patent
    filings, using only the first CPC code of each patent that
    has a valid filing date and non-empty application number.
    -------------------------------------------------------------
*/
WITH filings_per_year AS (          -- annual patent counts per level-5 CPC group
    SELECT
        FLOOR(p."filing_date" / 10000)             AS "year",                   -- YYYY
        LEFT(f.value:"code"::STRING, 4)            AS "group_code",             -- level-5 CPC symbol
        COUNT(*)                                   AS "filings"
    FROM PATENTS.PATENTS.PUBLICATIONS        p
         , LATERAL FLATTEN(input => p."cpc") f
    WHERE f.index = 0                              -- only the first CPC code
      AND p."filing_date" > 0                      -- keep valid dates
      AND COALESCE(p."application_number", '') <> ''   -- non-empty application #
    GROUP BY "year", "group_code"
),

ema AS (                           -- exponential moving average (α = 0.2)
    SELECT
        "year",
        "group_code",
        "filings",
        /*  EMA_t = 0.2*x_t + 0.8*EMA_{t-1}
            Implemented with running sums on the window              */
        SUM(0.2 * "filings") OVER (
            PARTITION BY "group_code"
            ORDER BY "year"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        -
        SUM(0.8 * 0.2 * "filings") OVER (
            PARTITION BY "group_code"
            ORDER BY "year"
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        )                                           AS "ema_0_2"
    FROM filings_per_year
),

best_year_group AS (               -- best (peak-EMA) year per CPC group
    SELECT
        "group_code",
        MAX_BY("year",  "ema_0_2") AS "best_year", -- year of maximum EMA
        MAX("ema_0_2")             AS "max_ema"    -- peak EMA value
    FROM ema
    GROUP BY "group_code"
)

SELECT
    b."group_code"                                 AS "cpc_group_code",
    d."titleFull"                                  AS "cpc_group_title",
    b."best_year",
    ROUND(b."max_ema", 4)                          AS "max_exponential_moving_average"
FROM best_year_group               b
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = b."group_code"
WHERE d."level" = 5                                -- ensure true level-5 groups
ORDER BY b."max_ema" DESC NULLS LAST;
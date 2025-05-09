WITH german_dec2016 AS (                -- patents granted in Germany during Dec‑2016
    SELECT
        p."publication_number",
        p."publication_date",
        f.value:"code"::STRING AS "cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") f
    WHERE p."country_code" = 'DE'
      AND p."grant_date" BETWEEN 20161201 AND 20161231
),
level4 AS (                             -- map each CPC code to its level‑4 group (e.g. B60)
    SELECT
        g."publication_number",
        g."publication_date",
        SUBSTR(g."cpc_code", 1, 3) AS "cpc_group"
    FROM german_dec2016 g
),
yearly AS (                             -- annual filing counts per CPC level‑4 group
    SELECT
        cd."symbol"                         AS "cpc_group",
        cd."titleFull"                      AS "cpc_title",
        FLOOR(l."publication_date" / 10000) AS "filing_year",
        COUNT(DISTINCT l."publication_number") AS "filings"
    FROM level4 l
    JOIN PATENTS.PATENTS.CPC_DEFINITION cd
         ON cd."symbol" = l."cpc_group"
        AND cd."level"  = 4.0
    GROUP BY cd."symbol", cd."titleFull", FLOOR(l."publication_date" / 10000)
),
ranked AS (                             -- descending row number per group for weighting
    SELECT
        y.*,
        ROW_NUMBER() OVER (PARTITION BY y."cpc_group"
                           ORDER BY y."filing_year" DESC) AS "rn_desc"
    FROM yearly y
),
ema AS (                                -- exponential moving average with α = 0.1
    SELECT
        r.*,
        SUM(r."filings" * POWER(0.9, r."rn_desc" - 1))
            OVER (PARTITION BY r."cpc_group"
                  ORDER BY r."filing_year" DESC) * 0.1     AS "ema_val"
    FROM ranked r
),
best AS (                               -- keep the year with the highest EMA per group
    SELECT
        e.*,
        ROW_NUMBER() OVER (PARTITION BY e."cpc_group"
                           ORDER BY e."ema_val" DESC) AS "rn"
    FROM ema e
)
SELECT
    "cpc_title" AS cpc_title,
    "cpc_group" AS cpc_group,
    "filing_year" AS year_with_max_exponential_moving_average
FROM best
WHERE "rn" = 1
ORDER BY "cpc_group";
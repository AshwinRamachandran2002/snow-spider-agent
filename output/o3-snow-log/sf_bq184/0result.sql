/* ==============================================================
   Daily cumulative number of contracts created on Ethereum
   (2017-01-01 ‑- 2021-12-31)
   ============================================================== */

WITH calendar AS (          -- one row per calendar day (1826 rows)
    SELECT
        DATEADD(
            day,
            SEQ4(),                      -- 0 .. 1825
            TO_DATE('2017-01-01')
        )          AS "DATE"
    FROM TABLE(
           GENERATOR(ROWCOUNT => 1826)   -- 2017-01-01 → 2021-12-31 inclusive
         )
),
categories AS (             -- the two creator classes
    SELECT 'external' AS "CREATOR_TYPE"
    UNION ALL
    SELECT 'contract'
),
contract_creations AS (     -- new contracts per day and class
    SELECT
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP("block_timestamp" / 1e6)
        )::DATE                         AS "DATE",
        CASE
            WHEN "trace_address" IS NULL
                 THEN 'external'
            ELSE 'contract'
        END                             AS "CREATOR_TYPE",
        COUNT(*)                        AS "DAILY_NEW"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "status"     = 1
      AND DATE_TRUNC(
              'day',
              TO_TIMESTAMP("block_timestamp" / 1e6)
          )::DATE BETWEEN '2017-01-01' AND '2021-12-31'
    GROUP BY "DATE", "CREATOR_TYPE"
),
daily AS (                  -- ensure every date / type pair appears
    SELECT
        cal."DATE",
        cat."CREATOR_TYPE",
        COALESCE(cc."DAILY_NEW", 0) AS "DAILY_NEW"
    FROM calendar   cal
    CROSS JOIN categories cat
    LEFT JOIN contract_creations cc
           ON  cal."DATE"          = cc."DATE"
           AND cat."CREATOR_TYPE"  = cc."CREATOR_TYPE"
),
cumulative AS (              -- running totals
    SELECT
        "DATE",
        "CREATOR_TYPE",
        SUM("DAILY_NEW") OVER (
            PARTITION BY "CREATOR_TYPE"
            ORDER BY      "DATE"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "CUMULATIVE_COUNT"
    FROM daily
)
SELECT                       -- final pivoted result
    "DATE",
    MAX(CASE WHEN "CREATOR_TYPE" = 'external'
             THEN "CUMULATIVE_COUNT" END) AS "CUMULATIVE_EXTERNAL_CREATIONS",
    MAX(CASE WHEN "CREATOR_TYPE" = 'contract'
             THEN "CUMULATIVE_COUNT" END) AS "CUMULATIVE_CONTRACT_CREATIONS"
FROM   cumulative
GROUP  BY "DATE"
ORDER  BY "DATE";
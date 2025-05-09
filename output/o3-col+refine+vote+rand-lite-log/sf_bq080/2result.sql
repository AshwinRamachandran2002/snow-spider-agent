WITH date_range AS (  -- generate one row per calendar day (32 days total)
    SELECT
        DATEADD(day, SEQ4(), DATE '2018-08-30') AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
daily_creates AS (    -- count daily contract-creation events by creator type
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))::DATE AS "day",
        SUM(CASE WHEN "trace_address" IS NULL     THEN 1 ELSE 0 END) AS "eoa_creates",
        SUM(CASE WHEN "trace_address" IS NOT NULL THEN 1 ELSE 0 END) AS "contract_creates"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))
            BETWEEN DATE '2018-08-30' AND DATE '2018-09-30'
    GROUP BY 1
),
merged AS (           -- ensure every day is present
    SELECT
        d."day",
        COALESCE(c."eoa_creates",      0) AS "eoa_creates",
        COALESCE(c."contract_creates", 0) AS "contract_creates"
    FROM date_range d
    LEFT JOIN daily_creates c
           ON d."day" = c."day"
)
SELECT
    "day",
    SUM("eoa_creates")      OVER (ORDER BY "day") AS "eoa_cumulative",
    SUM("contract_creates") OVER (ORDER BY "day") AS "contract_cumulative"
FROM merged
ORDER BY "day";
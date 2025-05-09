-- Daily cumulative number of Ethereum contracts created by
--   • external EOAs  (trace_address IS NULL/empty)
--   • other contracts (trace_address NOT NULL)
-- for every day from 30-Aug-2018 through 30-Sep-2018 (inclusive)
WITH calendar AS (   -- 32-day calendar covering the period
    SELECT
        DATEADD(day, seq4(), '2018-08-30') AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
daily AS (           -- contracts created each day, split by creator type
    SELECT
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP("block_timestamp" / 1e6)
        )                                                AS "day",
        CASE
            WHEN "trace_address" IS NULL
                 OR "trace_address" = '' THEN 'EOA'
            ELSE 'CONTRACT'
        END                                              AS "creator_type",
        COUNT(*)                                         AS "new_contracts"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "block_timestamp" BETWEEN 1535587200000000          -- 2018-08-30 00:00 UTC
                              AND 1538438399000000            -- 2018-09-30 23:59:59.999 UTC
    GROUP BY 1, 2
),
joined AS (          -- align daily counts to the full calendar
    SELECT
        cal."day",
        COALESCE(dae."new_contracts", 0)  AS "eoa_new",
        COALESCE(dac."new_contracts", 0)  AS "contract_new"
    FROM calendar cal
    LEFT JOIN daily dae
           ON cal."day" = dae."day"
          AND dae."creator_type" = 'EOA'
    LEFT JOIN daily dac
           ON cal."day" = dac."day"
          AND dac."creator_type" = 'CONTRACT'
)
SELECT
    "day",
    SUM("eoa_new")      OVER (ORDER BY "day") AS "cumulative_external_users",
    SUM("contract_new") OVER (ORDER BY "day") AS "cumulative_by_contracts"
FROM joined
ORDER BY "day";
WITH creation AS (
    /* contract‐creation traces in the required period */
    SELECT
        CAST(DATE_TRUNC('day',
               TO_TIMESTAMP("block_timestamp" / 1000000)) AS DATE)      AS "day",
        CASE
            WHEN "trace_address" IS NULL OR "trace_address" = ''
                 THEN 'external'               /* created directly by EOA */
            ELSE 'contract'                    /* created by another contract */
        END                                                         AS "creator_type",
        COUNT(*)                                                    AS "cnt"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND TO_TIMESTAMP("block_timestamp" / 1000000)
            BETWEEN '2018-08-30' AND '2018-09-30 23:59:59'
    GROUP BY 1, 2
),
dates AS (
    /* every calendar day in the interval 30‑Aug‑2018 … 30‑Sep‑2018 (32 days) */
    SELECT
        DATEADD(day, seq4(), DATE '2018-08-30')  AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
daily AS (
    /* join creations to the full date list, filling missing days with zeros */
    SELECT
        d."day",
        COALESCE(SUM(CASE WHEN c."creator_type" = 'external'  THEN c."cnt" END), 0) AS "external_cnt",
        COALESCE(SUM(CASE WHEN c."creator_type" = 'contract'  THEN c."cnt" END), 0) AS "contract_cnt"
    FROM dates d
    LEFT JOIN creation c
           ON d."day" = c."day"
    GROUP BY d."day"
),
cumulative AS (
    /* running totals to obtain strictly increasing cumulative figures */
    SELECT
        "day",
        SUM("external_cnt")  OVER (ORDER BY "day")  AS "cumulative_external",
        SUM("contract_cnt")  OVER (ORDER BY "day")  AS "cumulative_contract"
    FROM daily
)
SELECT
    "day",
    "cumulative_external",
    "cumulative_contract"
FROM cumulative
ORDER BY "day";
WITH
    -- all calendar days in requested range (inclusive)
    "date_range" AS (
        SELECT
            DATEADD(
                day,
                seq4(),
                DATE '2018-08-30'
            ) AS "date"
        FROM TABLE(GENERATOR(ROWCOUNT => 32))         -- 2018‑08‑30 … 2018‑09‑30 (32 days)
    ),

    -- daily contract‑creation counts split by creator type
    "creations" AS (
        SELECT
            TO_DATE(
                DATE_TRUNC(
                    'day',
                    TO_TIMESTAMP("block_timestamp" / 1000000)
                )
            )                                                          AS "date",
            CASE
                WHEN "trace_address" IS NULL OR "trace_address" = ''
                    THEN 'external'        -- created directly by an EOA
                ELSE 'contract'            -- created from another contract
            END                                                         AS "creator_type",
            COUNT(*)                                                     AS "cnt"
        FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
        WHERE ("trace_type" = 'create' OR "trace_type" = 'create2')
          AND TO_TIMESTAMP("block_timestamp" / 1000000)
                BETWEEN '2018-08-30' AND '2018-09-30 23:59:59'
        GROUP BY 1, 2
    ),

    -- daily totals, 0 when none created
    "daily" AS (
        SELECT
            d."date",
            COALESCE(
                SUM(CASE WHEN c."creator_type" = 'external'  THEN c."cnt" END),
                0
            ) AS "daily_external",
            COALESCE(
                SUM(CASE WHEN c."creator_type" = 'contract'  THEN c."cnt" END),
                0
            ) AS "daily_contract"
        FROM "date_range" d
        LEFT JOIN "creations" c
               ON d."date" = c."date"
        GROUP BY d."date"
    )

-- cumulative running totals (non‑decreasing)
SELECT
    "date",
    SUM("daily_external") OVER (
        ORDER BY "date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "cumulative_external_creations",
    SUM("daily_contract") OVER (
        ORDER BY "date"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "cumulative_contract_creations"
FROM "daily"
ORDER BY "date";
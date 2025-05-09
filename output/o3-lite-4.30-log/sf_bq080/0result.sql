WITH calendar AS (
    SELECT DATEADD(day, seq4(), '2018-08-30') AS "date"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))
),
eoa_daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "date",
        COUNT(*) AS "eoa_daily"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "trace_address" IS NULL
      AND "block_timestamp" >= 1535587200000000  -- 2018‑08‑30 00:00:00
      AND "block_timestamp" <  1538352000000000  -- 2018‑10‑01 00:00:00 (exclusive)
    GROUP BY 1
),
internal_daily AS (
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "date",
        COUNT(*) AS "internal_daily"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND "trace_address" IS NOT NULL
      AND "block_timestamp" >= 1535587200000000
      AND "block_timestamp" <  1538352000000000
    GROUP BY 1
),
merged AS (
    SELECT
        c."date",
        COALESCE(e."eoa_daily",      0) AS "eoa_daily",
        COALESCE(i."internal_daily", 0) AS "internal_daily"
    FROM calendar c
    LEFT JOIN eoa_daily      e USING ("date")
    LEFT JOIN internal_daily i USING ("date")
)
SELECT
    "date",
    SUM("eoa_daily")     OVER (ORDER BY "date") AS "cumulative_eoa_contracts",
    SUM("internal_daily") OVER (ORDER BY "date") AS "cumulative_internal_contracts"
FROM merged
ORDER BY "date";
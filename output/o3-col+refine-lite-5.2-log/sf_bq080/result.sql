/*  Daily cumulative count of smart‑contract creations (external‑user vs contract‑created)
    between 30‑Aug‑2018 and 30‑Sep‑2018 (inclusive)                                  */

WITH calendar AS (               -- one row per day in the target window
    SELECT
        DATEADD(day, seq4(), '2018-08-30'::date) AS "day"
    FROM TABLE(GENERATOR(ROWCOUNT => 32))        -- 32 days → 30‑Aug‑2018 .. 30‑Sep‑2018
),
external_daily AS (              -- contracts created directly by EOAs
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))  AS "day",
        COUNT(*)                                                    AS "cnt_external"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND ("trace_address" IS NULL OR "trace_address" = '')
      AND "block_timestamp" BETWEEN 1535587200000000    -- 2018‑08‑30 00:00:00 UTC
                               AND 1538351999000000     -- 2018‑09‑30 23:59:59 UTC
    GROUP BY 1
),
internal_daily AS (              -- contracts created by other contracts
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("block_timestamp" / 1e6))  AS "day",
        COUNT(*)                                                    AS "cnt_contract"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    WHERE "trace_type" = 'create'
      AND ("trace_address" IS NOT NULL AND "trace_address" <> '')
      AND "block_timestamp" BETWEEN 1535587200000000
                               AND 1538351999000000
    GROUP BY 1
)

SELECT
    c."day",
    /* cumulative totals (strictly non‑decreasing) */
    SUM(COALESCE(e."cnt_external", 0)) OVER (ORDER BY c."day") AS "cumulative_external_creates",
    SUM(COALESCE(i."cnt_contract", 0)) OVER (ORDER BY c."day") AS "cumulative_contract_creates"
FROM calendar            AS c
LEFT JOIN external_daily AS e ON c."day" = e."day"
LEFT JOIN internal_daily AS i ON c."day" = i."day"
ORDER BY c."day";
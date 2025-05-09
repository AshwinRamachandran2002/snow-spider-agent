WITH union_tx AS (
    /* all Oct-2017 transactions (inputs + outputs) */
    SELECT
        REGEXP_SUBSTR("addresses", '"([^"]+)"', 1, 1, 'e', 1)             AS "btc_address",
        TO_DECIMAL("value")                                               AS "value_sat",
        "block_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    WHERE "block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000

    UNION ALL

    SELECT
        REGEXP_SUBSTR("addresses", '"([^"]+)"', 1, 1, 'e', 1)             AS "btc_address",
        TO_DECIMAL("value")                                               AS "value_sat",
        "block_timestamp"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
    WHERE "block_timestamp" BETWEEN 1506816000000000 AND 1509494399000000
),
addr_last AS (
    /* each address’ last Oct-2017 tx-time */
    SELECT
        "btc_address",
        MAX("block_timestamp") AS "last_ts"
    FROM union_tx
    GROUP BY "btc_address"
),
latest_ts AS (
    /* latest Oct-2017 timestamp reached by any address */
    SELECT MAX("last_ts") AS "max_last_ts"
    FROM addr_last
),
candidate AS (
    /* addresses whose final Oct-2017 tx happened at that latest moment */
    SELECT "btc_address"
    FROM addr_last, latest_ts
    WHERE "last_ts" = "max_last_ts"
),
ranked AS (
    /* sum Oct-2017 values for those addresses */
    SELECT
        u."btc_address",
        SUM(u."value_sat") AS "total_value"
    FROM union_tx u
    JOIN candidate c
      ON u."btc_address" = c."btc_address"
    GROUP BY u."btc_address"
)
SELECT
    "btc_address",
    "total_value"
FROM ranked
ORDER BY "total_value" DESC NULLS LAST, "btc_address"
LIMIT 1;
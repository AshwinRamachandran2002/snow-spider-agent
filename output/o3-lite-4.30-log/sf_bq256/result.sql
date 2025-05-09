WITH
-- Successful external transactions before 2021‑09‑01 UTC
tx AS (
    SELECT
        "from_address",
        "to_address",
        "value",
        "gas_price",
        "receipt_gas_used"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
    WHERE "receipt_status" = 1
      AND "block_timestamp" < 1630454400000000
),
-- Address with the highest count of such transactions
top_sender AS (
    SELECT "from_address" AS address
    FROM tx
    GROUP BY "from_address"
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
-- External transactions involving that address (gas fee added)
ext AS (
    SELECT
        t.*,
        (t."gas_price" * t."receipt_gas_used") AS gas_fee
    FROM tx t
    JOIN top_sender a
      ON t."from_address" = a.address
      OR t."to_address"   = a.address
),
-- Internal value‑moving traces (excluding delegatecall/callcode/staticcall)
tr AS (
    SELECT
        "from_address",
        "to_address",
        "value"
    FROM CRYPTO.CRYPTO_ETHEREUM.TRACES
    JOIN top_sender a
      ON ("from_address" = a.address OR "to_address" = a.address)
    WHERE "block_timestamp" < 1630454400000000
      AND "status" = 1
      AND "trace_type" IN ('call','suicide','reward')
      AND COALESCE("call_type",'') NOT IN ('delegatecall','callcode','staticcall')
)
SELECT
    a.address                                                              AS address,
    ROUND(
        (
            /* incoming Wei */
            COALESCE((SELECT SUM("value") FROM ext WHERE "to_address"   = a.address),0) +
            COALESCE((SELECT SUM("value") FROM tr  WHERE "to_address"   = a.address),0)
          -
            /* outgoing Wei */
            COALESCE((SELECT SUM("value") FROM ext WHERE "from_address" = a.address),0) -
            COALESCE((SELECT SUM("value") FROM tr  WHERE "from_address" = a.address),0)
          -
            /* gas fees */
            COALESCE((SELECT SUM(gas_fee)  FROM ext WHERE "from_address" = a.address),0)
        ) / 1e18, 4)                                                       AS final_balance_ether
FROM top_sender a;
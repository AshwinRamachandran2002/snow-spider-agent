WITH april_tx AS (   -- transactions in April‑2023
    SELECT "hash"
    FROM CRYPTO.CRYPTO_DASH.TRANSACTIONS
    WHERE "block_timestamp_month" = '2023-04-01'
),
outputs AS (         -- credits
    SELECT
        ARRAY_TO_STRING(TO_ARRAY(o."addresses"), ',')   AS dash_address,
        o."type"                                        AS addr_type,
        o."value"                                       AS amount
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS o
    JOIN april_tx t
      ON o."transaction_hash" = t."hash"
),
inputs AS (          -- debits (negative)
    SELECT
        ARRAY_TO_STRING(TO_ARRAY(i."addresses"), ',')   AS dash_address,
        i."type"                                        AS addr_type,
        -i."value"                                      AS amount
    FROM CRYPTO.CRYPTO_DASH.INPUTS i
    JOIN april_tx t
      ON i."transaction_hash" = t."hash"
),
movements AS (       -- union of credits and debits
    SELECT * FROM outputs
    UNION ALL
    SELECT * FROM inputs
),
balances AS (        -- net balance per address & type
    SELECT
        dash_address,
        addr_type,
        SUM(amount) AS balance
    FROM movements
    GROUP BY dash_address, addr_type
),
extremes AS (        -- highest & lowest balances
    SELECT
        dash_address,
        balance,
        RANK() OVER (ORDER BY balance DESC) AS rk_high,
        RANK() OVER (ORDER BY balance ASC)  AS rk_low
    FROM balances
)
SELECT
    dash_address,
    ROUND(balance, 4) AS balance
FROM extremes
WHERE rk_high = 1
   OR rk_low  = 1
ORDER BY balance DESC;
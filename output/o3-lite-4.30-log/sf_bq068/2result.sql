WITH params AS (
    SELECT 
        1393632000000000::NUMBER AS ts_start,   -- 2014‑03‑01
        1396310400000000::NUMBER AS ts_end      -- 2014‑04‑01
),

credits AS (
    SELECT
        "type"            AS address_type,
        SUM("value")      AS amount                -- positive (credits)
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS, params
    WHERE "block_timestamp" >= ts_start
      AND "block_timestamp" <  ts_end
    GROUP BY "type"
),

debits AS (
    SELECT
        "type"            AS address_type,
        -SUM("value")     AS amount                -- negative (debits)
    FROM CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS, params
    WHERE "block_timestamp" >= ts_start
      AND "block_timestamp" <  ts_end
    GROUP BY "type"
),

final_balances AS (   -- net balance per address type
    SELECT
        address_type,
        SUM(amount) AS final_balance
    FROM (
        SELECT * FROM credits
        UNION ALL
        SELECT * FROM debits
    )
    GROUP BY address_type
),

extremes AS (
    SELECT 
        MAX(final_balance) AS max_bal,
        MIN(final_balance) AS min_bal
    FROM final_balances
)

SELECT
    fb.address_type,
    TO_DECIMAL(ex.max_bal,38,4) AS max_final_balance_satoshis,
    TO_DECIMAL(ex.min_bal,38,4) AS min_final_balance_satoshis
FROM final_balances fb
CROSS JOIN extremes ex
WHERE fb.final_balance IN (ex.max_bal, ex.min_bal)
ORDER BY fb.final_balance DESC;
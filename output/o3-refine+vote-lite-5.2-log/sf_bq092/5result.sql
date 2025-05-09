WITH all_entries AS (
    /* credits = outputs (positive) */
    SELECT
        ARRAY_TO_STRING("addresses", ',')       AS "address",
        "type",
        "value"                                 AS amount,
        "block_timestamp"
    FROM CRYPTO.CRYPTO_DASH."OUTPUTS"

    UNION ALL
    
    /* debits = inputs (negative) */
    SELECT
        ARRAY_TO_STRING("addresses", ',')       AS "address",
        "type",
        - "value"                               AS amount,
        "block_timestamp"
    FROM CRYPTO.CRYPTO_DASH."INPUTS"
),
april_2023 AS (
    /* keep only rows whose block‑timestamp falls in April‑2023 */
    SELECT *
    FROM all_entries
    WHERE DATE_TRUNC('month', TO_TIMESTAMP("block_timestamp" / 1e6)) = '2023-04-01'
),
balances AS (
    /* net balance per (address , type) using double‑entry bookkeeping */
    SELECT
        "address",
        "type",
        SUM(amount) AS balance
    FROM april_2023
    GROUP BY
        "address",
        "type"
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY balance DESC) AS r_high,
        DENSE_RANK() OVER (ORDER BY balance ASC)  AS r_low
    FROM balances
)
SELECT
    CASE WHEN r_high = 1 THEN 'HIGHEST' ELSE 'LOWEST' END AS category,
    "address",
    "type",
    balance
FROM ranked
WHERE r_high = 1
   OR r_low  = 1;
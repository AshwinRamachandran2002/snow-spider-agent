WITH
/* ---------- outputs are credits (+) ---------- */
outputs AS (
    SELECT
        ARRAY_TO_STRING(PARSE_JSON("addresses"), ',')     AS "address",
        "type",
        "value"                                           AS amt
    FROM CRYPTO.CRYPTO_DASH.OUTPUTS
    WHERE DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp"/1e6))
          = DATE '2023-04-01'
),
/* ---------- inputs are debits (−) ------------ */
inputs  AS (
    SELECT
        ARRAY_TO_STRING(PARSE_JSON("addresses"), ',')     AS "address",
        "type",
        - "value"                                         AS amt            -- negate
    FROM CRYPTO.CRYPTO_DASH.INPUTS
    WHERE DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ("block_timestamp"/1e6))
          = DATE '2023-04-01'
),
/* ---------- aggregate per address‑type -------- */
balances AS (
    SELECT
        "address",
        "type",
        SUM(amt) AS balance
    FROM (SELECT * FROM outputs
          UNION ALL
          SELECT * FROM inputs)
    GROUP BY "address", "type"
),
/* ---------- pick max & min ------------------- */
extremes AS (
    SELECT *
    FROM balances
    WHERE balance = (SELECT MAX(balance) FROM balances)
       OR balance = (SELECT MIN(balance) FROM balances)
)
SELECT
    "address",
    "type",
    balance
FROM extremes
ORDER BY balance DESC NULLS LAST;
WITH apr23_blocks AS (     -- Dash blocks in April‑2023
    SELECT  "number" AS block_number
    FROM    CRYPTO.CRYPTO_DASH."BLOCKS"
    WHERE   "timestamp_month" = '2023-04-01'
),
-- credits : outputs  ( + value )
outputs_apr AS (
    SELECT
        ARRAY_TO_STRING(TRY_PARSE_JSON("addresses"), ',') AS "address",
        "type",
        CAST("value" AS DECIMAL(38,9))                    AS amt
    FROM   CRYPTO.CRYPTO_DASH."OUTPUTS"
    WHERE  "block_number" IN (SELECT block_number FROM apr23_blocks)
),
-- debits : inputs  ( – value )
inputs_apr AS (
    SELECT
        ARRAY_TO_STRING(TRY_PARSE_JSON("addresses"), ',') AS "address",
        "type",
        -CAST("value" AS DECIMAL(38,9))                   AS amt   -- negative
    FROM   CRYPTO.CRYPTO_DASH."INPUTS"
    WHERE  "block_number" IN (SELECT block_number FROM apr23_blocks)
),
balances AS (            -- net balance per address‑type
    SELECT  "address",
            "type",
            SUM(amt) AS balance
    FROM   (
            SELECT * FROM outputs_apr
            UNION ALL
            SELECT * FROM inputs_apr
           )
    GROUP  BY "address","type"
),
-- highest balance
hi AS (
    SELECT 'HIGHEST' AS label, b.*
    FROM   balances b
    ORDER  BY b.balance DESC
    LIMIT  1
),
-- lowest balance
lo AS (
    SELECT 'LOWEST'  AS label, b.*
    FROM   balances b
    ORDER  BY b.balance ASC
    LIMIT  1
)
SELECT label,
       "address",
       "type",
       balance
FROM   (
        SELECT * FROM hi
        UNION ALL
        SELECT * FROM lo
       )
ORDER  BY label;
WITH
/*--------------------------------------------------------------------
  Credits (outputs) during April-2023 – amounts are positive
--------------------------------------------------------------------*/
outputs_month AS (
    SELECT
        ARRAY_TO_STRING(o."addresses", ',')          AS "address",
        o."type"                                     AS "type",
        CAST(o."value" AS DOUBLE)                    AS amount      -- credit
    FROM CRYPTO.CRYPTO_DASH."OUTPUTS" o
    JOIN CRYPTO.CRYPTO_DASH."BLOCKS"  b
          ON o."block_hash" = b."hash"
    WHERE b."timestamp_month" = '2023-04-01'
),
/*--------------------------------------------------------------------
  Debits (inputs) during April-2023 – amounts are negative
--------------------------------------------------------------------*/
inputs_month AS (
    SELECT
        ARRAY_TO_STRING(i."addresses", ',')          AS "address",
        i."type"                                     AS "type",
        -CAST(i."value" AS DOUBLE)                   AS amount      -- debit
    FROM CRYPTO.CRYPTO_DASH."INPUTS"  i
    JOIN CRYPTO.CRYPTO_DASH."BLOCKS"  b
          ON i."block_hash" = b."hash"
    WHERE b."timestamp_month" = '2023-04-01'
),
/*--------------------------------------------------------------------
  Net balance per (address , type)
--------------------------------------------------------------------*/
balances AS (
    SELECT
        "address",
        "type",
        SUM(amount) AS balance
    FROM (
        SELECT * FROM outputs_month
        UNION ALL
        SELECT * FROM inputs_month
    )
    GROUP BY "address", "type"
),
/*--------------------------------------------------------------------
  Identify highest and lowest balances
--------------------------------------------------------------------*/
extremes AS (
    SELECT
        "address",
        "type",
        balance,
        RANK() OVER (ORDER BY balance DESC) AS r_high,
        RANK() OVER (ORDER BY balance ASC ) AS r_low
    FROM balances
)
/*--------------------------------------------------------------------
  Return the extreme balances
--------------------------------------------------------------------*/
SELECT 'HIGHEST' AS "LEVEL", "address", "type", balance
FROM   extremes
WHERE  r_high = 1

UNION ALL

SELECT 'LOWEST'  AS "LEVEL", "address", "type", balance
FROM   extremes
WHERE  r_low  = 1;
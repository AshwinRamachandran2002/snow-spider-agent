WITH
/* -----------------------------------------------------------
   1. debit side (inputs) – amounts are negative
----------------------------------------------------------- */
input_flows AS (
    SELECT
        ARRAY_TO_STRING(i."addresses"::ARRAY, ',')  AS "dash_address",
        i."type",
        SUM(i."value") * -1                         AS "amount"
    FROM   "CRYPTO"."CRYPTO_DASH"."INPUTS"        i
    JOIN   "CRYPTO"."CRYPTO_DASH"."TRANSACTIONS"  t
           ON i."transaction_hash" = t."hash"
    WHERE  t."block_timestamp_month" = '2023-04-01'
    GROUP  BY 1,2
),
/* -----------------------------------------------------------
   2. credit side (outputs) – amounts are positive
----------------------------------------------------------- */
output_flows AS (
    SELECT
        ARRAY_TO_STRING(o."addresses"::ARRAY, ',')  AS "dash_address",
        o."type",
        SUM(o."value")                              AS "amount"
    FROM   "CRYPTO"."CRYPTO_DASH"."OUTPUTS"       o
    JOIN   "CRYPTO"."CRYPTO_DASH"."TRANSACTIONS"  t
           ON o."transaction_hash" = t."hash"
    WHERE  t."block_timestamp_month" = '2023-04-01'
    GROUP  BY 1,2
),
/* -----------------------------------------------------------
   3. net balance per address & script type (rounded to 4 decimal places)
----------------------------------------------------------- */
balances AS (
    SELECT  "dash_address",
            "type",
            ROUND(SUM("amount"), 4) AS "balance"
    FROM   (
        SELECT * FROM input_flows
        UNION ALL
        SELECT * FROM output_flows
    )
    GROUP  BY 1,2
),
/* -----------------------------------------------------------
   4. pick highest and lowest balances
----------------------------------------------------------- */
ranked AS (
    SELECT  "dash_address",
            "balance",
            ROW_NUMBER() OVER (ORDER BY "balance" DESC NULLS LAST) AS rn_high,
            ROW_NUMBER() OVER (ORDER BY "balance" ASC  NULLS LAST) AS rn_low
    FROM    balances
)
SELECT  "dash_address", "balance"
FROM    ranked
WHERE   rn_high = 1 OR rn_low = 1
ORDER BY "balance" DESC;
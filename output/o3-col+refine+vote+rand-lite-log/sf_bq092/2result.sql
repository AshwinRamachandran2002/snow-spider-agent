/* Highest and lowest Dash address balances for April-2023 */
WITH
/* ---------- 1.  Outputs (credits) ---------- */
output_rows AS (
    SELECT
        ARRAY_TO_STRING(
            ARRAY_AGG(f.value::STRING) WITHIN GROUP (ORDER BY f.index),
            ','
        )                               AS "address",
        o."type",
        o."value"                       AS "amount"
    FROM CRYPTO.CRYPTO_DASH."OUTPUTS" o
    JOIN CRYPTO.CRYPTO_DASH."BLOCKS"  b  ON o."block_number" = b."number"
         , LATERAL FLATTEN(INPUT => o."addresses") f
    WHERE b."timestamp_month" = '2023-04-01'
    GROUP BY o."transaction_hash",
             o."index",
             o."type",
             o."value"
),
/* ---------- 2.  Inputs (debits) ------------- */
input_rows AS (
    SELECT
        ARRAY_TO_STRING(
            ARRAY_AGG(f.value::STRING) WITHIN GROUP (ORDER BY f.index),
            ','
        )                               AS "address",
        i."type",
        i."value"                       AS "amount"
    FROM CRYPTO.CRYPTO_DASH."INPUTS"  i
    JOIN CRYPTO.CRYPTO_DASH."BLOCKS"  b  ON i."block_number" = b."number"
         , LATERAL FLATTEN(INPUT => i."addresses") f
    WHERE b."timestamp_month" = '2023-04-01'
    GROUP BY i."transaction_hash",
             i."index",
             i."type",
             i."value"
),
/* ---------- 3.  Aggregate credits & debits --- */
credits AS (
    SELECT "address", "type", SUM("amount")        AS "amt"
    FROM   output_rows
    GROUP  BY "address", "type"
),
debits  AS (
    SELECT "address", "type", -SUM("amount")       AS "amt"
    FROM   input_rows
    GROUP  BY "address", "type"
),
/* ---------- 4.  Net balance per address ------ */
net AS (
    SELECT "address",
           "type",
           SUM("amt")              AS "net_balance"
    FROM (
        SELECT * FROM credits
        UNION ALL
        SELECT * FROM debits
    )
    GROUP BY "address", "type"
),
/* ---------- 5.  Highest & lowest balances ---- */
extremes AS (
      ( SELECT 'HIGHEST' AS "kind", "address", "type", "net_balance"
        FROM   net
        ORDER  BY "net_balance" DESC NULLS LAST
        LIMIT  1 )
      UNION ALL
      ( SELECT 'LOWEST'  AS "kind", "address", "type", "net_balance"
        FROM   net
        ORDER  BY "net_balance" ASC  NULLS LAST
        LIMIT  1 )
)
SELECT *
FROM   extremes;
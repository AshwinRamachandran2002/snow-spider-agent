/* ------------------------------------------------------------
   Highest and lowest Dash address balances for April‑2023
   (double‑entry: outputs = credit, inputs = debit)
   ------------------------------------------------------------ */
WITH
/* April‑2023 Dash transactions */
"DASH_TX_APRIL" AS (
    SELECT  "hash" AS "txhash"
    FROM    CRYPTO.CRYPTO_DASH."TRANSACTIONS"
    WHERE   "block_timestamp_month" = '2023-04-01'
),

/* Positive leg: outputs  ------------------------------------ */
"OUTPUT_SIDE" AS (
    SELECT
        f.value::string                          AS "address",
        o."type"                                 AS "type",
        SUM(o."value")                           AS "amount"      -- credit
    FROM    CRYPTO.CRYPTO_DASH."OUTPUTS" o
    JOIN    "DASH_TX_APRIL" t
            ON t."txhash" = o."transaction_hash"
    ,       LATERAL FLATTEN(INPUT => o."addresses") f
    GROUP BY f.value::string, o."type"
),

/* Negative leg: inputs  ------------------------------------- */
"INPUT_SIDE" AS (
    SELECT
        f.value::string                          AS "address",
        i."type"                                 AS "type",
        -SUM(i."value")                          AS "amount"      -- debit
    FROM    CRYPTO.CRYPTO_DASH."INPUTS" i
    JOIN    "DASH_TX_APRIL" t
            ON t."txhash" = i."transaction_hash"
    ,       LATERAL FLATTEN(INPUT => i."addresses") f
    GROUP BY f.value::string, i."type"
),

/* Net balances per (address , type) -------------------------- */
"BALANCES" AS (
    SELECT  "address",
            "type",
            SUM("amount") AS "balance"
    FROM   (
            SELECT * FROM "OUTPUT_SIDE"
            UNION ALL
            SELECT * FROM "INPUT_SIDE"
           )
    GROUP BY "address", "type"
)

/* Highest and lowest balances -------------------------------- */
SELECT  'HIGHEST' AS "category",
        "address",
        "type",
        "balance"
FROM    "BALANCES"
QUALIFY "balance" = MAX("balance") OVER()
UNION ALL
SELECT  'LOWEST'  AS "category",
        "address",
        "type",
        "balance"
FROM    "BALANCES"
QUALIFY "balance" = MIN("balance") OVER();
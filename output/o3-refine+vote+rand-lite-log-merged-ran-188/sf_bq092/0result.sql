WITH io AS (   -- outputs (credits, +) and inputs (debits, -)
    SELECT
        CASE 
            WHEN TYPEOF("addresses") = 'ARRAY' 
                 THEN ARRAY_TO_STRING("addresses", ',') 
            ELSE "addresses"::STRING 
        END                                   AS "address",
        "type",
        "value"                              AS "amount",
        "block_number"
    FROM CRYPTO.CRYPTO_DASH."OUTPUTS"

    UNION ALL

    SELECT
        CASE 
            WHEN TYPEOF("addresses") = 'ARRAY' 
                 THEN ARRAY_TO_STRING("addresses", ',') 
            ELSE "addresses"::STRING 
        END                                   AS "address",
        "type",
        - "value"                            AS "amount",   -- debit
        "block_number"
    FROM CRYPTO.CRYPTO_DASH."INPUTS"
),
-- retain only April‑2023 records
apr_23 AS (
    SELECT  i."address",
            i."type",
            i."amount"
    FROM    io i
    JOIN    CRYPTO.CRYPTO_DASH."BLOCKS" b
           ON i."block_number" = b."number"
    WHERE   b."timestamp_month" = '2023-04-01'
),
-- net balance per address + type
balances AS (
    SELECT  "address",
            "type",
            SUM("amount") AS "balance"
    FROM    apr_23
    GROUP BY "address", "type"
),
extremes AS (   -- highest and lowest balances
    (SELECT 'HIGHEST' AS "category", * 
     FROM   balances 
     ORDER BY "balance" DESC NULLS LAST 
     LIMIT 1)
    UNION ALL
    (SELECT 'LOWEST'  AS "category", * 
     FROM   balances 
     ORDER BY "balance" ASC NULLS LAST 
     LIMIT 1)
)
SELECT * 
FROM   extremes;
-- 1)  Get every block that lies between 1-Mar-2014 (incl.) and 1-Apr-2014 (incl.)
WITH blocks_in_period AS (            -- micro-second → TIMESTAMP → DATE
    SELECT  "number"
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.BLOCKS
    WHERE   TO_DATE( TO_TIMESTAMP( "timestamp" / 1000000 ) ) 
                BETWEEN DATE '2014-03-01' AND DATE '2014-04-01'
),

-- 2)  Credits  = transaction outputs  (positive amounts)
credits AS (
    SELECT  
        addr.value::STRING                AS "address",
        o."type"                          AS "address_type",
        CAST( o."value" AS DOUBLE )       AS "amount"        --  positive
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.OUTPUTS  o
    JOIN    blocks_in_period               b   ON o."block_number" = b."number"
    ,       LATERAL FLATTEN( input => o."addresses") addr
),

-- 3)  Debits   = transaction inputs   (negative amounts)
debits AS (
    SELECT  
        addr.value::STRING                AS "address",
        i."type"                          AS "address_type",
        -CAST( i."value" AS DOUBLE )      AS "amount"        --  negative
    FROM    CRYPTO.CRYPTO_BITCOIN_CASH.INPUTS   i
    JOIN    blocks_in_period               b   ON i."block_number" = b."number"
    ,       LATERAL FLATTEN( input => i."addresses") addr
),

-- 4)  Final balance per address (credits + debits)
balances AS (
    SELECT
        "address_type",
        "address",
        SUM( "amount" )  AS "final_balance"
    FROM (
        SELECT * FROM credits
        UNION ALL
        SELECT * FROM debits
    )
    GROUP BY "address_type", "address"
)

-- 5)  Max / Min final balances for every address-type
SELECT
    "address_type",
    MAX( "final_balance" ) AS "max_final_balance",
    MIN( "final_balance" ) AS "min_final_balance"
FROM   balances
GROUP  BY "address_type"
ORDER  BY "address_type";
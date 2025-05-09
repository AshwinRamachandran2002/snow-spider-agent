WITH april_blocks AS (
    SELECT  "hash"
    FROM    CRYPTO.CRYPTO_DASH."BLOCKS"
    WHERE   "timestamp_month" = '2023-04-01'
),
credits AS (   -- outputs = positive amounts
    SELECT  ARRAY_TO_STRING(o."addresses", ',')   AS "addr",
            o."type",
            SUM(o."value")                       AS "val"
    FROM    CRYPTO.CRYPTO_DASH."OUTPUTS" o
    JOIN    april_blocks            b   ON  o."block_hash" = b."hash"
    GROUP BY 1,2
),
debits AS (     -- inputs = negative amounts
    SELECT  ARRAY_TO_STRING(i."addresses", ',')   AS "addr",
            i."type",
            -SUM(i."value")                      AS "val"
    FROM    CRYPTO.CRYPTO_DASH."INPUTS"  i
    JOIN    april_blocks            b   ON  i."block_hash" = b."hash"
    GROUP BY 1,2
),
all_moves AS (
    SELECT * FROM credits
    UNION ALL
    SELECT * FROM debits
),
balances AS (
    SELECT  "addr",
            "type",
            SUM("val")          AS "net_balance"
    FROM    all_moves
    GROUP BY 1,2
)
SELECT  "addr",
        "type",
        "net_balance"
FROM    balances
QUALIFY ROW_NUMBER() OVER (ORDER BY "net_balance" DESC) = 1   -- highest
     OR ROW_NUMBER() OVER (ORDER BY "net_balance"  ASC) = 1   -- lowest
ORDER BY "net_balance" DESC;
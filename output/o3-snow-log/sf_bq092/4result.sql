WITH april_blocks AS (          -- all Dash blocks in April-2023
    SELECT DISTINCT "block_number"
    FROM   "CRYPTO"."CRYPTO_DASH"."TRANSACTIONS"
    WHERE  "block_timestamp_month" = '2023-04-01'
),

-- credits  (outputs) ---------------------------------------------------------
outs AS (
    SELECT
        ARRAY_TO_STRING("addresses", ',')       AS "addr",
        "type",
        SUM("value")                            AS "amt"          -- positive
    FROM   "CRYPTO"."CRYPTO_DASH"."OUTPUTS"
    WHERE  "block_number" IN (SELECT "block_number" FROM april_blocks)
    GROUP  BY ARRAY_TO_STRING("addresses", ','), "type"
),

-- debits  (inputs) -----------------------------------------------------------
ins AS (
    SELECT
        ARRAY_TO_STRING("addresses", ',')       AS "addr",
        "type",
        -SUM("value")                           AS "amt"          -- negative
    FROM   "CRYPTO"."CRYPTO_DASH"."INPUTS"
    WHERE  "block_number" IN (SELECT "block_number" FROM april_blocks)
    GROUP  BY ARRAY_TO_STRING("addresses", ','), "type"
),

-- net balance per address + type --------------------------------------------
net AS (
    SELECT   "addr", "type", SUM("amt") AS "balance"
    FROM    (SELECT * FROM outs
             UNION ALL
             SELECT * FROM ins)
    GROUP BY "addr", "type"
),

highest AS (                 -- highest balance
    SELECT  *
    FROM    net
    ORDER BY "balance" DESC NULLS LAST
    LIMIT   1
),

lowest  AS (                 -- lowest balance
    SELECT  *
    FROM    net
    ORDER BY "balance" ASC NULLS LAST
    LIMIT   1
)

-- return both rows -----------------------------------------------------------
SELECT * FROM highest
UNION ALL
SELECT * FROM lowest;
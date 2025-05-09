-- Highest and lowest April-2023 net balances for Dash addresses
WITH tx_apr_2023 AS (           -- all April-2023 Dash tx hashes
    SELECT "hash"
    FROM   CRYPTO.CRYPTO_DASH."TRANSACTIONS"
    WHERE  "block_timestamp_month" = '2023-04-01'
),
credits AS (                    -- sums of OUTPUT values (credits)
    SELECT
        ARRAY_TO_STRING(o."addresses", ',')         AS "addr",
        o."type",
        SUM(o."value")                              AS "credits"
    FROM   CRYPTO.CRYPTO_DASH."OUTPUTS" o
    JOIN   tx_apr_2023            t  ON o."transaction_hash" = t."hash"
    GROUP  BY 1,2
),
debits AS (                     -- sums of INPUT values (debits)
    SELECT
        ARRAY_TO_STRING(i."addresses", ',')         AS "addr",
        i."type",
        SUM(i."value")                              AS "debits"
    FROM   CRYPTO.CRYPTO_DASH."INPUTS"  i
    JOIN   tx_apr_2023            t  ON i."transaction_hash" = t."hash"
    GROUP  BY 1,2
),
net AS (                         -- net balance per (addr,type)
    SELECT
        COALESCE(c."addr", d."addr")                AS "address_concat",
        COALESCE(c."type", d."type")                AS "type",
        COALESCE(c."credits", 0) - COALESCE(d."debits", 0)  AS "net_balance"
    FROM   credits c
    FULL  JOIN debits  d
           ON  c."addr" = d."addr"
           AND c."type" = d."type"
)
-- pick the single highest and single lowest balance
(
    SELECT * 
    FROM   net
    ORDER  BY "net_balance" DESC NULLS LAST
    LIMIT  1
)
UNION ALL
(
    SELECT * 
    FROM   net
    ORDER  BY "net_balance" ASC NULLS LAST
    LIMIT  1
);
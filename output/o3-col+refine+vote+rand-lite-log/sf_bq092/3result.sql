-- Highest-positive and lowest-negative Dash net balances for April-2023
WITH month_blocks AS (
    SELECT "hash" AS block_hash
    FROM   CRYPTO.CRYPTO_DASH."BLOCKS"
    WHERE  "timestamp_month" = '2023-04-01'
),
credits AS (   -- sum of OUTPUT values (credits)
    SELECT ARRAY_TO_STRING(o."addresses", ',') AS "address",
           o."type",
           SUM(o."value")                     AS credit
    FROM   CRYPTO.CRYPTO_DASH."OUTPUTS"  o
    JOIN   month_blocks                     b  ON o."block_hash" = b.block_hash
    GROUP  BY ARRAY_TO_STRING(o."addresses", ','), o."type"
),
debits AS (    -- sum of INPUT values (debits)
    SELECT ARRAY_TO_STRING(i."addresses", ',') AS "address",
           i."type",
           SUM(i."value")                     AS debit
    FROM   CRYPTO.CRYPTO_DASH."INPUTS"   i
    JOIN   month_blocks                     b  ON i."block_hash" = b.block_hash
    GROUP  BY ARRAY_TO_STRING(i."addresses", ','), i."type"
),
net AS (       -- credits minus debits
    SELECT COALESCE(c."address", d."address")      AS "address",
           COALESCE(c."type",    d."type")         AS "type",
           COALESCE(c.credit,0) - COALESCE(d.debit,0) AS net_balance
    FROM   credits c
    FULL   JOIN debits d
           ON c."address" = d."address"
          AND c."type"    = d."type"
)
SELECT "address",
       "type",
       net_balance
FROM   net
WHERE  net_balance = (SELECT MAX(net_balance) FROM net)   -- highest
    OR net_balance = (SELECT MIN(net_balance) FROM net)   -- lowest
ORDER  BY net_balance DESC NULLS LAST;
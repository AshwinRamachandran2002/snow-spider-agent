/* Highest & lowest Dash address balances for April-2023 */
WITH
/* credits (outputs) */
credits AS (
    SELECT
        f.VALUE::STRING                       AS "address",
        o."type",
        SUM(o."value")                        AS "credit"
    FROM  CRYPTO.CRYPTO_DASH."OUTPUTS"  o
    JOIN  CRYPTO.CRYPTO_DASH."BLOCKS"   b
          ON o."block_number" = b."number",
          LATERAL FLATTEN(INPUT => o."addresses") f
    WHERE b."timestamp_month" = '2023-04-01'
    GROUP BY f.VALUE::STRING, o."type"
),
/* debits (inputs) */
debits AS (
    SELECT
        f.VALUE::STRING                       AS "address",
        i."type",
        SUM(i."value")                        AS "debit"
    FROM  CRYPTO.CRYPTO_DASH."INPUTS"   i
    JOIN  CRYPTO.CRYPTO_DASH."BLOCKS"   b
          ON i."block_number" = b."number",
          LATERAL FLATTEN(INPUT => i."addresses") f
    WHERE b."timestamp_month" = '2023-04-01'
    GROUP BY f.VALUE::STRING, i."type"
),
/* net balance per address-type */
net AS (
    SELECT
        COALESCE(c."address", d."address")            AS "address",
        COALESCE(c."type",    d."type")               AS "type",
        COALESCE(c."credit",0) - COALESCE(d."debit",0) AS "net_balance"
    FROM   credits c
    FULL  JOIN debits  d
           ON c."address" = d."address"
          AND c."type"    = d."type"
),
/* overall min & max balances */
limits AS (
    SELECT
        MIN("net_balance") AS "min_bal",
        MAX("net_balance") AS "max_bal"
    FROM   net
)
/* return rows whose balance equals the min or max */
SELECT  n."address",
        n."type",
        n."net_balance"
FROM    net n,
        limits l
WHERE   n."net_balance" IN (l."min_bal", l."max_bal")
ORDER BY n."net_balance" ASC;
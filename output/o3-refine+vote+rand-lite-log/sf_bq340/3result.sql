WITH
params AS (
    SELECT
        '0x0d8775f648430679a709e98d2b0cb6250d2887ef'  AS "TOKEN1",
        '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'  AS "TOKEN2"
),
addresses AS (      -- every address that ever sent OR received either token
    SELECT DISTINCT "from_address" AS "address"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS, params
    WHERE  "token_address" IN ("TOKEN1","TOKEN2")
      AND  "from_address"  <> '0x0000000000000000000000000000000000000000'
    UNION
    SELECT DISTINCT "to_address"   AS "address"
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS, params
    WHERE  "token_address" IN ("TOKEN1","TOKEN2")
      AND  "to_address"    <> '0x0000000000000000000000000000000000000000'
),
balances AS (       -- current net balance per token for each address
    SELECT
        a."address",
        SUM( CASE WHEN t."token_address" = p."TOKEN1"
                  THEN IFF(t."to_address" = a."address",
                           TO_DECIMAL(t."value"),0)
                     - IFF(t."from_address" = a."address",
                           TO_DECIMAL(t."value"),0)
             ELSE 0 END) AS "bal_token1",
        SUM( CASE WHEN t."token_address" = p."TOKEN2"
                  THEN IFF(t."to_address" = a."address",
                           TO_DECIMAL(t."value"),0)
                     - IFF(t."from_address" = a."address",
                           TO_DECIMAL(t."value"),0)
             ELSE 0 END) AS "bal_token2"
    FROM   addresses                      a
    JOIN   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS  t
           ON ( t."from_address" = a."address"
                 OR t."to_address" = a."address" )
    ,      params                       p
    WHERE  t."token_address" IN (p."TOKEN1",p."TOKEN2")
    GROUP  BY a."address"
),
ranked AS (          -- absolute difference between the two token balances
    SELECT
        "address",
        ABS("bal_token1" - "bal_token2") AS "abs_diff"
    FROM balances
)
SELECT
    "address"
FROM   ranked
ORDER  BY "abs_diff" DESC NULLS LAST
LIMIT  6;
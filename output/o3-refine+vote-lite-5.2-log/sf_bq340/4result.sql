WITH relevant_transfers AS (

    /* 1.  negative change for senders (from_address) */
    SELECT  LOWER("from_address")      AS "address",
            -CAST("value" AS NUMBER(38,0))  AS "delta"          -- tokens spent
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   LOWER("token_address") IN
            ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
             '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')

    UNION ALL

    /* 2.  positive change for recipients (to_address) */
    SELECT  LOWER("to_address")        AS "address",
            CAST("value" AS NUMBER(38,0))   AS "delta"          -- tokens received
    FROM    CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE   LOWER("token_address") IN
            ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
             '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
),

/* 3.  for every address keep the single largest absolute balance change it ever experienced */
address_changes AS (
    SELECT  "address",
            MAX(ABS("delta")) AS "largest_single_change"
    FROM    relevant_transfers
    WHERE   "address" <> '0x0000000000000000000000000000000000000000'   -- omit zero‑address
    GROUP BY "address"
)

/* 4.  top six addresses with the biggest absolute change */
SELECT      "address",
            "largest_single_change"   AS "absolute_balance_difference"
FROM        address_changes
ORDER BY    "largest_single_change" DESC NULLS LAST,
            "address"
LIMIT 6;
WITH relevant_transfers AS (
    /* 1 ─ Signed movements for the two tokens                                      */
    SELECT
        "token_address",
        "to_address"   AS "address",
        "block_number",
        "log_index",
        TRY_TO_NUMBER("value")       AS "delta"          -- incoming (+)
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  "token_address" IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
           )

    UNION ALL

    SELECT
        "token_address",
        "from_address" AS "address",
        "block_number",
        "log_index",
        -TRY_TO_NUMBER("value")      AS "delta"          -- outgoing (‑)
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  "token_address" IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
           )
),
latest_change AS (
    /* 2 ─ Most‑recent transfer per (address × token)                               */
    SELECT
        "address",
        "token_address",
        "delta",
        ROW_NUMBER() OVER (
            PARTITION BY "address", "token_address"
            ORDER BY     "block_number" DESC,
                         "log_index"   DESC
        ) AS rn
    FROM   relevant_transfers
    WHERE  LOWER("address") <> '0x0000000000000000000000000000000000000000'
),
abs_deltas AS (
    /* 3 ─ Absolute size of that latest balance change                              */
    SELECT
        "address",
        ABS("delta") AS "abs_change"
    FROM   latest_change
    WHERE  rn = 1
)
/* 4 ─ Top six addresses by absolute change                                         */
SELECT  "address"
FROM    abs_deltas
ORDER BY "abs_change" DESC NULLS LAST,
         "address"
LIMIT 6;
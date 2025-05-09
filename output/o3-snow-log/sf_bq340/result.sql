WITH token_moves AS (
    /* all transfers (outgoing and incoming) of the two tokens              */
    /* Badger (BAT) ‑ 0x0d877…, 1inch ‑ 0x1e15…                             */
    SELECT  LOWER("from_address") AS address ,
            TO_NUMBER("value")     AS abs_change
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   LOWER("token_address") IN (
               '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',   -- BAT
               '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'    -- 1INCH
            )
      AND   LOWER("from_address") <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    SELECT  LOWER("to_address")   AS address ,
            TO_NUMBER("value")    AS abs_change
    FROM    CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE   LOWER("token_address") IN (
               '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
               '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
            )
      AND   LOWER("to_address") <> '0x0000000000000000000000000000000000000000'
)
/* aggregate by address and pick the biggest single-step balance change    */
SELECT  address,
        MAX(abs_change) AS largest_abs_balance_change
FROM    token_moves
GROUP BY address
ORDER BY largest_abs_balance_change DESC NULLS LAST
LIMIT 6;
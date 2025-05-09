WITH transfers AS (   -- every balance‐impacting transfer for the two tokens
    SELECT
        LOWER("token_address")               AS token_address,
        "block_number",
        "block_timestamp",
        LOWER("to_address")                  AS address,
        TO_NUMBER("value")                   AS amount_change          -- tokens received
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                                      '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')

    UNION ALL

    SELECT
        LOWER("token_address")               AS token_address,
        "block_number",
        "block_timestamp",
        LOWER("from_address")                AS address,
        -TO_NUMBER("value")                  AS amount_change          -- tokens sent (negative)
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") IN ('0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
                                      '0x1e15c05cbad367f044cbfbafda3d9a1510db5513')
),

-- net change per (address, token, block)
by_block AS (
    SELECT
        address,
        token_address,
        "block_number",
        SUM(amount_change) AS net_change
    FROM transfers
    GROUP BY address, token_address, "block_number"
),

-- latest block for every (address, token)
latest_change AS (
    SELECT
        address,
        token_address,
        net_change,
        ROW_NUMBER() OVER (PARTITION BY address, token_address
                           ORDER BY "block_number" DESC) AS rn
    FROM by_block
),

-- most recent balance delta per (address, token)
latest_only AS (
    SELECT address,
           token_address,
           net_change
    FROM   latest_change
    WHERE  rn = 1
),

-- total absolute change (latest – previous) per address across the two tokens
addr_change AS (
    SELECT
        address,
        SUM(ABS(net_change)) AS total_abs_change
    FROM   latest_only
    GROUP BY address
)

SELECT
    address
FROM   addr_change
WHERE  address <> '0x0000000000000000000000000000000000000000'
ORDER  BY total_abs_change DESC NULLS LAST
LIMIT 6;
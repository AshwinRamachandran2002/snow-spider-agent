-- first 5 Mints + first 5 Burns for Uniswap-V3 ETH/USDC pool
WITH labeled AS (
    SELECT
        CASE
            WHEN "topics" ILIKE '%0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde%' THEN 'Mint'
            ELSE 'Burn'
        END                                   AS "event_type",
        "block_timestamp",
        "block_number",
        "transaction_hash",
        ROW_NUMBER() OVER (
            PARTITION BY
                CASE
                    WHEN "topics" ILIKE '%0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde%' THEN 'Mint'
                    ELSE 'Burn'
                END
            ORDER BY "block_timestamp" ASC
        )                                     AS rn
    FROM CRYPTO.CRYPTO_ETHEREUM.LOGS
    WHERE "address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
      AND (
           "topics" ILIKE '%0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde%'
        OR "topics" ILIKE '%0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c%'
      )
)
SELECT
    "event_type",
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM labeled
WHERE rn <= 5          -- first 5 of each event type
ORDER BY "block_timestamp" ASC;
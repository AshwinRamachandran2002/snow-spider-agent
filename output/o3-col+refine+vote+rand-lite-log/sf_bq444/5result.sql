WITH ranked_events AS (
    SELECT
        "block_timestamp",
        "block_number",
        "transaction_hash",
        CASE
            WHEN "topics"[0]::STRING = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'
                 THEN 'Mint'
            ELSE 'Burn'
        END                                            AS event_type,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                            WHEN "topics"[0]::STRING = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'
                                 THEN 'Mint'
                            ELSE 'Burn'
                          END
            ORDER BY "block_timestamp"
        )                                             AS rn
    FROM CRYPTO.CRYPTO_ETHEREUM.LOGS
    WHERE "address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
      AND "topics"[0]::STRING IN (
          '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde',  -- Mint
          '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'   -- Burn
      )
)
SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM ranked_events
WHERE rn <= 5           -- first five of each (Mint & Burn)
ORDER BY "block_timestamp";
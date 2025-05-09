WITH ranked_events AS (
    SELECT
        l."block_timestamp",
        l."block_number",
        l."transaction_hash",
        CASE
            WHEN f.value::STRING = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'
                 THEN 'MINT'
            ELSE 'BURN'
        END                                             AS event_type,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                             WHEN f.value::STRING = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'
                                  THEN 'MINT'
                             ELSE 'BURN'
                         END
            ORDER BY l."block_timestamp"
        )                                              AS rn
    FROM CRYPTO.CRYPTO_ETHEREUM."LOGS" l,
         LATERAL FLATTEN(input => l."topics") f
    WHERE UPPER(l."address") = '0X8AD599C3A0FF1DE082011EFDDC58F1908EB6E6D8'
      AND f.index = 0
      AND f.value::STRING IN (
            '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde', -- Mint topic
            '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'  -- Burn topic
      )
)

SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM ranked_events
WHERE rn <= 5    -- first five of each event type
ORDER BY "block_timestamp";
WITH ranked_events AS (
    SELECT
        l."block_timestamp",
        l."block_number",
        l."transaction_hash",
        t.value::STRING AS "topic",
        ROW_NUMBER() OVER (
            PARTITION BY t.value::STRING
            ORDER BY l."block_timestamp"
        ) AS "rn"
    FROM CRYPTO.CRYPTO_ETHEREUM."LOGS" AS l,
         LATERAL FLATTEN(input => l."topics") AS t
    WHERE l."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
      AND t.value::STRING IN (
            '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde',  -- Mint
            '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'   -- Burn
      )
)
SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM ranked_events
WHERE "rn" <= 5          -- first five for each event type
ORDER BY "block_timestamp";
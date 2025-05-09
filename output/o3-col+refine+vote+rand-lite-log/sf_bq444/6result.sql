SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM (
    SELECT
        l."block_timestamp",
        l."block_number",
        l."transaction_hash",
        ROW_NUMBER() OVER (
            PARTITION BY l."topics"[0]        -- separate Mint vs Burn
            ORDER BY     l."block_timestamp"   -- earliest first
        ) AS rn
    FROM CRYPTO.CRYPTO_ETHEREUM.LOGS AS l
    WHERE l."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
      AND l."topics"[0] IN (
            '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde',  -- Mint
            '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'   -- Burn
          )
)
WHERE rn <= 5                              -- first five Mint and first five Burn
ORDER BY "block_timestamp";
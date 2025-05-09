WITH
    mint AS (
        SELECT
            l."block_timestamp",
            l."block_number",
            l."transaction_hash"
        FROM CRYPTO.CRYPTO_ETHEREUM."LOGS"            AS l,
             LATERAL FLATTEN(INPUT => PARSE_JSON(l."topics")) AS f
        WHERE l."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
          AND f."INDEX"   = 0
          AND f."VALUE"::STRING = '0x7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde'   -- Mint
        ORDER BY l."block_timestamp"
        LIMIT 5
    ),
    burn AS (
        SELECT
            l."block_timestamp",
            l."block_number",
            l."transaction_hash"
        FROM CRYPTO.CRYPTO_ETHEREUM."LOGS"            AS l,
             LATERAL FLATTEN(INPUT => PARSE_JSON(l."topics")) AS f
        WHERE l."address" = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
          AND f."INDEX"   = 0
          AND f."VALUE"::STRING = '0x0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c'   -- Burn
        ORDER BY l."block_timestamp"
        LIMIT 5
    )

SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM (
    SELECT * FROM mint
    UNION ALL
    SELECT * FROM burn
)
ORDER BY "block_timestamp";
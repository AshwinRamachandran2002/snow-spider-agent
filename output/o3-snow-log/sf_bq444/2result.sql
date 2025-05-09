WITH
    mint_events AS (
        SELECT
            "block_timestamp",
            "block_number",
            "transaction_hash",
            ROW_NUMBER() OVER (ORDER BY "block_timestamp" ASC) AS rn
        FROM CRYPTO.CRYPTO_ETHEREUM.LOGS
        WHERE LOWER("address") = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
          AND LOWER("topics"::STRING) LIKE '%7a53080ba414158be7ec69b987b5fb7d07dee101fe85488f0853ae16239d0bde%'
        QUALIFY rn <= 5
    ),
    burn_events AS (
        SELECT
            "block_timestamp",
            "block_number",
            "transaction_hash",
            ROW_NUMBER() OVER (ORDER BY "block_timestamp" ASC) AS rn
        FROM CRYPTO.CRYPTO_ETHEREUM.LOGS
        WHERE LOWER("address") = '0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8'
          AND LOWER("topics"::STRING) LIKE '%0c396cd989a39f4459b5fa1aed6a9a8dcdbc45908acfd67e028cd568da98982c%'
        QUALIFY rn <= 5
    )

SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM mint_events

UNION ALL

SELECT
    "block_timestamp",
    "block_number",
    "transaction_hash"
FROM burn_events

ORDER BY "block_timestamp" ASC;
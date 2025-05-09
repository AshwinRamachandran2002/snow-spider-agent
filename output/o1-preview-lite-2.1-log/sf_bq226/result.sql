SELECT
    'https://explorer.cronoscan.com/address/0x' || SUBSTRING("topic_from", -40) AS "url"
FROM (
    SELECT
        t."transaction_hash",
        t."topics"[1]::string AS "topic_from"
    FROM
        "GOOG_BLOCKCHAIN"."GOOG_BLOCKCHAIN_ARBITRUM_ONE_US"."LOGS" t
    WHERE
        t."block_timestamp" >= 1672531200
        AND t."topics"[0]::string = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
        AND t."address" IS NOT NULL
) tx
GROUP BY
    "topic_from"
ORDER BY
    COUNT(*) DESC NULLS LAST
LIMIT 1;
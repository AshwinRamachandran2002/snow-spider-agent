WITH filtered AS (
    SELECT
        LOWER("topics"[1]::string) AS sender
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US."LOGS"
    WHERE "block_timestamp" >= 1672531200000000              -- ≥ 2023‑01‑01 (micro‑seconds)
      -- block larger than 4096 bytes  ⇒  data string longer than 4096*2 hex chars + "0x"
      AND LENGTH("data") > (4096 * 2 + 2)
      -- non‑null “to” address (present as 3rd topic in a Transfer‑style event)
      AND "topics"[2] IS NOT NULL
)
SELECT
    CONCAT('https://cronoscan.com/address/', sender) AS sender_url
FROM filtered
GROUP BY sender
ORDER BY COUNT(*) DESC NULLS LAST, sender       -- most‑frequent sender
LIMIT 1;
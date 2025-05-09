WITH
    -- all token contracts whose symbol is exactly `BNB`
    "BNB_TOKENS" AS (
        SELECT DISTINCT LOWER("address") AS "token_address"
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKENS
        WHERE UPPER("symbol") = 'BNB'
    ),

    -- every transfer of a BNB token
    "BNB_TRANSFERS" AS (
        SELECT
            LOWER(tt."from_address") AS "from_address",
            LOWER(tt."to_address")   AS "to_address",
            TRY_TO_DECIMAL(tt."value")       AS "value_wei"          -- raw amount in Wei (10‑18)
        FROM ETHEREUM_BLOCKCHAIN.ETHEREUM_BLOCKCHAIN.TOKEN_TRANSFERS tt
        INNER JOIN "BNB_TOKENS" bt
                ON LOWER(tt."token_address") = bt."token_address"
    ),

    -- aggregate total in‐flows and out‐flows that involve only NON‑zero addresses
    "TOTALS" AS (
        SELECT
            SUM(
                CASE
                    WHEN "to_address" <> '0x0000000000000000000000000000000000000000'
                    THEN "value_wei"
                    ELSE 0
                END
            ) AS "total_received_nonzero",
            SUM(
                CASE
                    WHEN "from_address" <> '0x0000000000000000000000000000000000000000'
                    THEN "value_wei"
                    ELSE 0
                END
            ) AS "total_sent_nonzero"
        FROM "BNB_TRANSFERS"
    )

-- circulating supply = Σ(received by non‑zero) – Σ(sent from non‑zero)
SELECT
    ("total_received_nonzero" - "total_sent_nonzero") / 1e18
        AS "BNB_CIRCULATING_SUPPLY"
FROM "TOTALS";
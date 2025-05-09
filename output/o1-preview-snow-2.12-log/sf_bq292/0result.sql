SELECT
    TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)), 'Mon-YYYY') AS "Month",
    ROUND(SUM(CASE WHEN "input_count" >= 5 AND "output_count" >= 5 AND "is_coinbase" = FALSE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS "Percentage_of_CoinJoin_Transactions",
    ROUND(SUM(CASE WHEN "input_count" >= 5 AND "output_count" >= 5 AND "is_coinbase" = FALSE THEN "output_count" ELSE 0 END) * 100.0 / SUM("output_count"), 4) AS "Percentage_of_CoinJoin_UTXOs",
    ROUND(SUM(CASE WHEN "input_count" >= 5 AND "output_count" >= 5 AND "is_coinbase" = FALSE THEN "output_value" ELSE 0 END) * 100.0 / SUM("output_value"), 4) AS "Percentage_of_CoinJoin_Volume"
FROM "CRYPTO"."CRYPTO_BITCOIN"."TRANSACTIONS"
WHERE TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) >= TO_DATE('2023-07-01', 'YYYY-MM-DD')
GROUP BY DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
ORDER BY DATE_TRUNC('month', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) ASC;
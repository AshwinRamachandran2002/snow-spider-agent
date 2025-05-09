SELECT DATE(TO_TIMESTAMP("block_timestamp" / 1000000)) AS "Date",
       ROUND(SUM("amount"), 4) AS "Total_Transaction_Amount"
FROM CRYPTO.CRYPTO_ZILLIQA.TRANSACTIONS
WHERE "block_timestamp" < 1640995200000000
  AND "accepted" = TRUE
  AND "success" = TRUE
GROUP BY DATE(TO_TIMESTAMP("block_timestamp" / 1000000))
ORDER BY SUM("amount") DESC NULLS LAST
LIMIT 1;
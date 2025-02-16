-- Task: List all the minting and burning transactions of USDC tokens (address `0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48`) for 2023, based on Ethereum transactions. For each transaction, show the date, transaction hash, operation type (Mint or Burn), and the amount (in millions). Limit the results to 100 entries.
SELECT
  TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) AS "Date",
  "hash" AS "Transaction Hash",
  CASE
    WHEN "input" LIKE '0x40c10f19%' THEN 'Mint'
    ELSE 'Burn'
  END AS "Operation",
  CAST(CONCAT('0x', LTRIM(SUBSTRING("input",
     CASE
         WHEN "input" LIKE '0x40c10f19%' THEN 75
         ELSE 11
     END, 64), '0')) AS FLOAT) / 1000000 AS "Amount (in millions)"
FROM
  "CRYPTO"."CRYPTO_ETHEREUM"."TRANSACTIONS"
WHERE
  TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1000000)) BETWEEN '2023-01-01' AND '2023-12-31'
  AND "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
  AND ("input" LIKE '0x42966c68%'
       OR "input" LIKE '0x40c10f19%')
ORDER BY
  "Date" DESC
LIMIT 100;
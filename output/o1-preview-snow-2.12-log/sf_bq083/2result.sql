SELECT DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "Date",
       TO_CHAR(
         SUM(
           CASE
             WHEN "input" LIKE '0x40c10f19%'
               THEN TRY_TO_NUMBER(SUBSTRING("input", 75, 64), 16) / 1e6
             WHEN "input" LIKE '0x42966c68%'
               THEN -TRY_TO_NUMBER(SUBSTRING("input", 11, 64), 16) / 1e6
             ELSE 0
           END
         ),
         'FM$999,999,999,990.0000'
       ) AS "Δ Total Market Value"
FROM CRYPTO.CRYPTO_ETHEREUM.TRANSACTIONS
WHERE "to_address" = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
  AND ("input" LIKE '0x40c10f19%' OR "input" LIKE '0x42966c68%')
  AND EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2023
GROUP BY "Date"
ORDER BY "Date" DESC NULLS LAST;
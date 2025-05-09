SELECT
  TO_CHAR(TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)), 'YYYY-MM-DD') AS "date",
  TO_CHAR(
    SUM(
      CASE
        WHEN LOWER("from_address") = '0x0000000000000000000000000000000000000000' THEN TO_DECIMAL("value") / 1e6  -- Mint
        WHEN LOWER("to_address") = '0x0000000000000000000000000000000000000000' THEN -TO_DECIMAL("value") / 1e6  -- Burn
        ELSE 0
      END
    ),
    'FM$999,999,999,990.0000'
  ) AS "Δ Total Market Value"
FROM
  "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
WHERE
  LOWER("token_address") = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
  AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) >= DATE '2023-01-01'
  AND TO_DATE(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) < DATE '2024-01-01'
GROUP BY
  "date"
ORDER BY
  "date";
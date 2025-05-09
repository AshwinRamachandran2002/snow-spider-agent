WITH "transfers" AS (

  /* outgoing amounts (negative) */
  SELECT
      LOWER("from_address") AS "address",
      - TO_NUMBER("value")      AS "amount"
  FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
  WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'

  UNION ALL

  /* incoming amounts (positive) */
  SELECT
      LOWER("to_address")   AS "address",
      TO_NUMBER("value")    AS "amount"
  FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
  WHERE LOWER("token_address") = '0xa92a861fc11b99b24296af880011b47f9cafb5ab'
)

SELECT
    "address"                  AS "ethereum_address",
    SUM("amount")              AS "balance"
FROM "transfers"
GROUP BY "address"
HAVING SUM("amount") > 0                         -- only positive net balances
ORDER BY
    SUM("amount") ASC NULLS LAST,                -- smallest positive first
    "address"
FETCH FIRST 3 ROWS ONLY;                         -- top‑3
WITH net_balances AS (
  SELECT
    "address",
    SUM("total_credits") - SUM("total_debits") AS "resulting_balance"
  FROM (
    -- Credits (Outputs)
    SELECT
      f.value::STRING AS "address",
      0 AS "total_debits",
      t."value" AS "total_credits"
    FROM
      "CRYPTO"."CRYPTO_DASH"."OUTPUTS" t,
      LATERAL FLATTEN(input => t."addresses") f
    WHERE
      t."block_timestamp" BETWEEN 1680307200000000 AND 1682812799000000

    UNION ALL

    -- Debits (Inputs)
    SELECT
      f.value::STRING AS "address",
      t."value" AS "total_debits",
      0 AS "total_credits"
    FROM
      "CRYPTO"."CRYPTO_DASH"."INPUTS" t,
      LATERAL FLATTEN(input => t."addresses") f
    WHERE
      t."block_timestamp" BETWEEN 1680307200000000 AND 1682812799000000
  ) GROUP BY "address"
)
SELECT "address", ROUND("resulting_balance", 4) AS "resulting_balance"
FROM (
  SELECT
    "address",
    "resulting_balance",
    RANK() OVER (ORDER BY "resulting_balance" DESC NULLS LAST) AS rank_desc,
    RANK() OVER (ORDER BY "resulting_balance" ASC NULLS LAST) AS rank_asc
  FROM net_balances
)
WHERE rank_desc = 1 OR rank_asc = 1
ORDER BY "resulting_balance" DESC NULLS LAST;
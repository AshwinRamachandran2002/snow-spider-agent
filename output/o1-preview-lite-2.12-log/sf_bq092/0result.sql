WITH net_balances AS (
  SELECT
    f.value::STRING AS "Address",
    SUM(t."value") AS "Resulting_Balance"
  FROM (
    SELECT
      t."addresses",
      -t."value" AS "value"
    FROM "CRYPTO"."CRYPTO_DASH"."INPUTS" t
    WHERE t."block_timestamp" >= 1680307200000000 AND t."block_timestamp" < 1682899200000000

    UNION ALL

    SELECT
      t."addresses",
      t."value" AS "value"
    FROM "CRYPTO"."CRYPTO_DASH"."OUTPUTS" t
    WHERE t."block_timestamp" >= 1680307200000000 AND t."block_timestamp" < 1682899200000000
  ) t,
  LATERAL FLATTEN(input => t."addresses") f
  GROUP BY f.value::STRING
)
SELECT "Address", "Resulting_Balance"
FROM net_balances
WHERE "Resulting_Balance" = (SELECT MAX("Resulting_Balance") FROM net_balances)
   OR "Resulting_Balance" = (SELECT MIN("Resulting_Balance") FROM net_balances);
WITH net_changes AS (
  SELECT 
    COALESCE(r."address", s."address") AS "Address",
    COALESCE(r."type", s."type") AS "Type",
    COALESCE(r."total_received", 0) - COALESCE(s."total_sent", 0) AS "NetChange"
  FROM
    (
      SELECT f.value::STRING AS "address", t."type", SUM(t."value") AS "total_received"
      FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."OUTPUTS" t,
           LATERAL FLATTEN(input => t."addresses") f
      WHERE t."block_timestamp" >= DATE_PART(EPOCH_MICROSECOND, TIMESTAMP '2023-04-01')
        AND t."block_timestamp" < DATE_PART(EPOCH_MICROSECOND, TIMESTAMP '2023-05-01')
      GROUP BY "address", t."type"
    ) r
  FULL OUTER JOIN
    (
      SELECT f.value::STRING AS "address", t."type", SUM(t."value") AS "total_sent"
      FROM "CRYPTO"."CRYPTO_BITCOIN_CASH"."INPUTS" t,
           LATERAL FLATTEN(input => t."addresses") f
      WHERE t."block_timestamp" >= DATE_PART(EPOCH_MICROSECOND, TIMESTAMP '2023-04-01')
        AND t."block_timestamp" < DATE_PART(EPOCH_MICROSECOND, TIMESTAMP '2023-05-01')
      GROUP BY "address", t."type"
    ) s
  ON r."address" = s."address" AND r."type" = s."type"
),
highest_net_change AS (
  SELECT "Address", "Type", ROUND("NetChange", 4) AS "NetChange"
  FROM net_changes
  ORDER BY "NetChange" DESC NULLS LAST
  LIMIT 1
),
lowest_net_change AS (
  SELECT "Address", "Type", ROUND("NetChange", 4) AS "NetChange"
  FROM net_changes
  ORDER BY "NetChange" ASC NULLS LAST
  LIMIT 1
)
SELECT * FROM highest_net_change
UNION ALL
SELECT * FROM lowest_net_change;
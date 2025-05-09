WITH
  "outs" AS (
      SELECT
          f.value::STRING           AS "address",
          o."block_timestamp"       AS "block_timestamp",
          o."value"                 AS "value"
      FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS" o,
           LATERAL FLATTEN(INPUT => o."addresses") f
      WHERE o."block_timestamp"
            BETWEEN 1506816000000000 AND 1509494399999999  -- 2017-10-01 .. 2017-10-31 (µs)
  ),

  "ins" AS (
      SELECT
          f.value::STRING           AS "address",
          i."block_timestamp"       AS "block_timestamp",
          i."value"                 AS "value"
      FROM CRYPTO.CRYPTO_BITCOIN."INPUTS" i,
           LATERAL FLATTEN(INPUT => i."addresses") f
      WHERE i."block_timestamp"
            BETWEEN 1506816000000000 AND 1509494399999999
  ),

  "all_tx" AS (
      SELECT * FROM "outs"
      UNION ALL
      SELECT * FROM "ins"
  ),

  "per_addr" AS (
      SELECT
          "address",
          MAX("block_timestamp")            AS "latest_ts",
          SUM("value")                      AS "total_value"
      FROM "all_tx"
      GROUP BY "address"
  ),

  "latest_cte" AS (
      SELECT MAX("latest_ts") AS "global_latest_ts"
      FROM "per_addr"
  )

SELECT
    p."address",
    p."latest_ts",
    p."total_value"
FROM "per_addr" p
JOIN "latest_cte" l
  ON p."latest_ts" = l."global_latest_ts"
ORDER BY p."total_value" DESC NULLS LAST
LIMIT 1;
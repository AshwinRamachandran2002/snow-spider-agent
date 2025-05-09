SELECT 
  AVG_2019 - AVG_2020 AS "difference_in_average_hourly_change"
FROM (
  SELECT
    (SELECT AVG("hourly_change") FROM (
      SELECT DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "hour",
             SUM("value"::FLOAT) AS "total_value",
             SUM("value"::FLOAT) - LAG(SUM("value"::FLOAT)) OVER (
               ORDER BY DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
             ) AS "hourly_change"
      FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
      WHERE
        "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND (
          "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
          OR "to_address" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
        )
        AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) >= '2019-01-01' 
        AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) < '2020-01-01'
      GROUP BY 1
    ) t1 WHERE "hourly_change" IS NOT NULL) AS AVG_2019,

    (SELECT AVG("hourly_change") FROM (
      SELECT DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "hour",
             SUM("value"::FLOAT) AS "total_value",
             SUM("value"::FLOAT) - LAG(SUM("value"::FLOAT)) OVER (
               ORDER BY DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))
             ) AS "hourly_change"
      FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
      WHERE
        "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND (
          "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
          OR "to_address" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
        )
        AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) >= '2020-01-01'
        AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6) <= '2020-12-31'
      GROUP BY 1
    ) t2 WHERE "hourly_change" IS NOT NULL) AS AVG_2020
) AS differences;
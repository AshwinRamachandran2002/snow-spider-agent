SELECT 
  ROUND(ABS(AVG_2020."average_hourly_value" - AVG_2019."average_hourly_value"), 4) AS "difference"
FROM 
  (
    SELECT AVG("average_value") AS "average_hourly_value"
    FROM (
      SELECT DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "hour",
             AVG(CAST("value" AS FLOAT)) AS "average_value"
      FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
      WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND ("from_address" IN ('0x8babf0ba311aab914c00e8fda7e8558a8b66de5d', 
                                '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
             OR "to_address" IN ('0x8babf0ba311aab914c00e8fda7e8558a8b66de5d', 
                                 '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'))
        AND EXTRACT(year FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2019
      GROUP BY "hour"
    ) AS "hourly_values"
  ) AS AVG_2019,
  (
    SELECT AVG("average_value") AS "average_hourly_value"
    FROM (
      SELECT DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) AS "hour",
             AVG(CAST("value" AS FLOAT)) AS "average_value"
      FROM "CRYPTO"."CRYPTO_ETHEREUM"."TOKEN_TRANSFERS"
      WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
        AND ("from_address" IN ('0x8babf0ba311aab914c00e8fda7e8558a8b66de5d', 
                                '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
             OR "to_address" IN ('0x8babf0ba311aab914c00e8fda7e8558a8b66de5d', 
                                 '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'))
        AND EXTRACT(year FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2020
      GROUP BY "hour"
    ) AS "hourly_values"
  ) AS AVG_2020;
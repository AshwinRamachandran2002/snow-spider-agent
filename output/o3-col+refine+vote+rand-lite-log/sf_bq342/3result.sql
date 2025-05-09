WITH hourly_sums AS (
    SELECT
        DATE_TRUNC('HOUR', TO_TIMESTAMP_NTZ("block_timestamp" / 1e6))             AS "hour",
        CASE 
            WHEN EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)) = 2019 THEN '2019'
            ELSE '2020'
        END                                                                        AS "yr",
        SUM("value"::NUMBER)                                                       AS "sum_value"
    FROM CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (
            "from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
         OR "to_address"   = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f'
      )
      AND TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)
          BETWEEN '2019-01-01' AND '2020-12-31 23:59:59'
    GROUP BY 1, 2
),
yearly_avg AS (
    SELECT
        "yr",
        AVG("sum_value") AS "avg_hr_value"
    FROM hourly_sums
    GROUP BY "yr"
)
SELECT
    MAX(CASE WHEN "yr" = '2020' THEN "avg_hr_value" END)
  - MAX(CASE WHEN "yr" = '2019' THEN "avg_hr_value" END)  AS "avg_hourly_difference"
FROM yearly_avg;
WITH filtered AS (
    SELECT  -- keep only the token and the two specified counterparties
           "value"::NUMBER          AS "val",
           "block_timestamp"
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  "token_address" = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND ("from_address" = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
           OR "to_address" = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
      AND "block_timestamp" BETWEEN 1546300800000000   -- 2019-01-01 00:00:00 UTC
                                AND 1609372799000000   -- 2020-12-31 23:59:59 UTC
),
hourly AS (                       -- average value inside every 1-hour bucket
    SELECT CASE
               WHEN "block_timestamp" < 1577836800000000   -- < 2020-01-01
                    THEN '2019' ELSE '2020' END            AS "yr",
           FLOOR("block_timestamp"/3600000000)             AS "hour_bucket",
           AVG("val")                                      AS "avg_val_hour"
    FROM   filtered
    GROUP BY 1, 2
),
yearly AS (                       -- overall average of those hourly averages per year
    SELECT "yr",
           AVG("avg_val_hour")    AS "overall_avg"
    FROM   hourly
    GROUP BY "yr"
)
SELECT  yearly_2020."overall_avg"
      - yearly_2019."overall_avg" AS "difference_avg_hourly_value"
FROM   (SELECT "overall_avg" FROM yearly WHERE "yr" = '2019') yearly_2019,
       (SELECT "overall_avg" FROM yearly WHERE "yr" = '2020') yearly_2020;
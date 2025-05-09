WITH filtered AS (   -- step 1 : keep only wanted token‑transfers
    SELECT
        TO_TIMESTAMP_NTZ("block_timestamp" / 1e6)              AS ts,
        TO_DECIMAL("value")                                    AS val
    FROM   CRYPTO.CRYPTO_ETHEREUM.TOKEN_TRANSFERS
    WHERE  LOWER("token_address")   = '0x68e54af74b22acaccffa04ccaad13be16ed14eac'
      AND (  LOWER("from_address")  = '0x8babf0ba311aab914c00e8fda7e8558a8b66de5d'
          OR LOWER("to_address")    = '0xfbd6c6b112214d949dcdfb1217153bc0a742862f')
      -- between 2019‑01‑01 00:00:00 and 2020‑12‑31 23:59:59 (micro‑seconds)
      AND  "block_timestamp" BETWEEN 1546300800000000 AND 1609459199000000
), hourly AS (        -- step 2 : sum per blockchain hour
    SELECT
        DATE_TRUNC('hour', ts)            AS hr,
        SUM(val)                          AS hour_sum
    FROM   filtered
    GROUP  BY hr
), changes AS (       -- step 3 : hour‑to‑hour change
    SELECT
        hr,
        hour_sum - LAG(hour_sum) OVER (ORDER BY hr)   AS hour_change,
        YEAR(hr)                                      AS yr
    FROM   hourly
)
SELECT      -- step 4 : average hourly change per year and their difference
        AVG(CASE WHEN yr = 2020 THEN hour_change END) 
      - AVG(CASE WHEN yr = 2019 THEN hour_change END) AS "difference_avg_hourly_change"
FROM    changes
WHERE   hour_change IS NOT NULL;
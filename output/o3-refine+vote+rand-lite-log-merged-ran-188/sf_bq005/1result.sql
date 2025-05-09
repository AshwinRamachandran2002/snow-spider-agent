/* Daily average Bitcoin block interval (seconds) for 2023 – first 10 days */
WITH ordered AS (
    SELECT  "number",
            TO_TIMESTAMP_NTZ("timestamp" / 1e6)                 AS ts,
            ROW_NUMBER() OVER (ORDER BY "number")               AS rn
    FROM    CRYPTO.CRYPTO_BITCOIN.BLOCKS
    WHERE   "timestamp"
              BETWEEN DATE_PART('epoch_second'
                                , TO_TIMESTAMP_NTZ('2023-01-01'))                * 1000000
                  AND DATE_PART('epoch_second'
                                , TO_TIMESTAMP_NTZ('2023-12-31 23:59:59'))        * 1000000
), consecutive AS (
    /* self-join consecutive rows via the row numbers */
    SELECT  o1.ts  AS ts_curr,
            o0.ts  AS ts_prev
    FROM    ordered o1
    JOIN    ordered o0
      ON    o1.rn = o0.rn + 1              -- previous block
)
SELECT  DATE_TRUNC('day', ts_curr)                          AS calendar_day,
        AVG(DATEDIFF('second', ts_prev, ts_curr))           AS avg_interval_sec
FROM    consecutive
GROUP BY calendar_day
ORDER BY calendar_day
LIMIT   10;
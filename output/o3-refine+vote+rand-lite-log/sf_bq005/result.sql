SELECT 
    block_date                                   AS "date",
    AVG(interval_sec)                           AS "avg_interval_seconds"
FROM (
    /* Derive the elapsed time (in seconds) since the previous block */
    SELECT
        DATE(TO_TIMESTAMP_NTZ("timestamp" / 1e6))                                AS block_date,
        ( "timestamp" - LAG("timestamp") OVER (ORDER BY "number") ) / 1e6        AS interval_sec
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
) AS intervals
/* Keep only blocks whose own date is in 2023 and which are not the genesis block */
WHERE block_date BETWEEN '2023-01-01' AND '2023-12-31'
  AND interval_sec IS NOT NULL
GROUP BY block_date
ORDER BY block_date
LIMIT 10;
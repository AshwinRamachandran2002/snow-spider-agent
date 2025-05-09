/* monthly transaction totals and transactions-per-second for 2023 */
WITH base AS (
    /* pull year & month from the micro-second epoch timestamp */
    SELECT
        EXTRACT(YEAR  FROM TO_TIMESTAMP("block_timestamp" / 1000000))  AS yr,
        EXTRACT(MONTH FROM TO_TIMESTAMP("block_timestamp" / 1000000))  AS mo
    FROM GOOG_BLOCKCHAIN.GOOG_BLOCKCHAIN_ARBITRUM_ONE_US.LOGS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) = 2023
)
SELECT
    COUNT(*)                                                     AS "monthly_transaction_count",
    /* calculate seconds in the month with leap-year logic, then tx/sec */
    ROUND(
        COUNT(*) :: FLOAT
        /
        (CASE
             WHEN mo IN (1,3,5,7,8,10,12)                                   THEN 31 * 86400    -- 31-day months
             WHEN mo IN (4,6,9,11)                                         THEN 30 * 86400    -- 30-day months
             WHEN mo = 2
                  AND (MOD(yr,400)=0 OR (MOD(yr,4)=0 AND MOD(yr,100)<>0))  THEN 29 * 86400    -- February leap year
             ELSE 28 * 86400                                               -- February non-leap year
         END),
        4)                                                        AS "transactions_per_second",
    yr                                                           AS "year",
    LPAD(mo::VARCHAR, 2, '0')                                    AS "month"
FROM base
GROUP BY yr, mo
ORDER BY "monthly_transaction_count" DESC NULLS LAST;
-- Daily average Bitcoin block interval-lengths (seconds) for 2023.
WITH ordered AS (          -- give every block a sequential row-id
    SELECT
        "number",
        "timestamp",
        ROW_NUMBER() OVER (ORDER BY "number") AS rn
    FROM CRYPTO.CRYPTO_BITCOIN.BLOCKS
),
pairs AS (                 -- self-join to bring in the immediately-preceding block
    SELECT
        cur."timestamp"         AS cur_ts,
        prv."timestamp"         AS prev_ts
    FROM ordered cur
    JOIN ordered prv
          ON cur.rn = prv.rn + 1      -- previous row
),
intervals AS (             -- raw interval (µs → s) attached to the *later* block
    SELECT
        cur_ts,
        (cur_ts - prev_ts) / 1000000.0  AS interval_sec
    FROM pairs
),
daily AS (                 -- convert µs epoch → calendar date, keep 2023 rows only
    SELECT
        TO_DATE('1970-01-01') + FLOOR(cur_ts / 1000000 / 86400) AS block_date,
        interval_sec
    FROM intervals
    WHERE block_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    block_date                               AS "date",
    AVG(interval_sec)                        AS "avg_interval_sec"
FROM daily
GROUP BY block_date
ORDER BY block_date
LIMIT 10;
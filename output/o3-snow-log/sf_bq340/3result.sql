WITH transfers_filtered AS (
    SELECT
        LOWER("token_address")                               AS token_address ,
        LOWER("from_address")                                AS from_addr,
        LOWER("to_address")                                  AS to_addr,
        TRY_TO_DECIMAL("value")                              AS amount,
        TO_DATE(TO_TIMESTAMP("block_timestamp" / 1e6))       AS tx_date
    FROM   CRYPTO.CRYPTO_ETHEREUM."TOKEN_TRANSFERS"
    WHERE  LOWER("token_address") IN (
              '0x0d8775f648430679a709e98d2b0cb6250d2887ef0',
              '0x1e15c05cbad367f044cbfbafda3d9a1510db5513'
           )
),
-- transform to balance-change rows (+ for receiver, – for sender)
balance_changes AS (
    SELECT  token_address, tx_date,
            to_addr    AS address,
            amount     AS change
    FROM    transfers_filtered
    WHERE   to_addr <> '0x0000000000000000000000000000000000000000'

    UNION ALL

    SELECT  token_address, tx_date,
            from_addr  AS address,
           -amount     AS change
    FROM    transfers_filtered
    WHERE   from_addr <> '0x0000000000000000000000000000000000000000'
),
-- net change per address per day (across the two tokens)
daily_net AS (
    SELECT
        address,
        tx_date,
        SUM(change) AS net_change
    FROM   balance_changes
    GROUP  BY address, tx_date
),
-- running balance per address by day
daily_balance AS (
    SELECT
        address,
        tx_date,
        SUM(net_change)
          OVER (PARTITION BY address
                ORDER BY tx_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance
    FROM   daily_net
),
-- keep last two daily balances for each address
latest_two AS (
    SELECT
        address,
        tx_date,
        balance,
        DENSE_RANK() OVER (PARTITION BY address ORDER BY tx_date DESC) AS rnk
    FROM   daily_balance
),
pivoted AS (
    SELECT
        address,
        MAX(CASE WHEN rnk = 1 THEN balance END) AS current_balance,
        MAX(CASE WHEN rnk = 2 THEN balance END) AS previous_balance
    FROM   latest_two
    WHERE  rnk <= 2
    GROUP  BY address
),
diffs AS (
    SELECT
        address,
        ABS(current_balance - previous_balance) AS abs_diff
    FROM   pivoted
    WHERE  current_balance IS NOT NULL
       AND previous_balance IS NOT NULL
)
SELECT
    address                        AS "ADDRESS",
    abs_diff                       AS "ABSOLUTE_DIFFERENCE"
FROM   diffs
ORDER  BY abs_diff DESC NULLS LAST
LIMIT  6;
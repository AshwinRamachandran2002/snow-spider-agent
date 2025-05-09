WITH formatted_txns AS (
    SELECT
        txn_id,
        member_id,
        ticker,
        DATE(substr(txn_date, 7, 4) || '-' || substr(txn_date, 4, 2) || '-' || substr(txn_date, 1, 2)) AS txn_date,
        txn_type,
        quantity,
        percentage_fee,
        txn_time
    FROM bitcoin_transactions
),
formatted_prices AS (
    SELECT
        ticker,
        DATE(substr(market_date, 7, 4) || '-' || substr(market_date, 4, 2) || '-' || substr(market_date, 1, 2)) AS market_date,
        price
    FROM bitcoin_prices
),
dates AS (
    SELECT date FROM (
        SELECT txn_date AS date FROM formatted_txns
        UNION
        SELECT market_date AS date FROM formatted_prices
    )
    GROUP BY date
),
members AS (
    SELECT DISTINCT member_id FROM formatted_txns
),
tickers AS (
    SELECT DISTINCT ticker FROM formatted_txns
),
date_member_ticker AS (
    SELECT d.date, m.member_id, t.ticker
    FROM dates d
    CROSS JOIN members m
    CROSS JOIN tickers t
),
cumulative_txns AS (
    SELECT
        member_id,
        ticker,
        txn_date,
        SUM(CASE WHEN txn_type = 'BUY' THEN quantity ELSE -quantity END) OVER (
            PARTITION BY member_id, ticker
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_quantity
    FROM formatted_txns
),
daily_holdings AS (
    SELECT
        dmt.date,
        dmt.member_id,
        dmt.ticker,
        (
            SELECT cumulative_quantity
            FROM cumulative_txns ct
            WHERE ct.member_id = dmt.member_id
              AND ct.ticker = dmt.ticker
              AND ct.txn_date <= dmt.date
            ORDER BY ct.txn_date DESC
            LIMIT 1
        ) AS cumulative_quantity
    FROM date_member_ticker dmt
),
holdings_with_prices AS (
    SELECT
        dh.date,
        dh.member_id,
        dh.ticker,
        IFNULL(dh.cumulative_quantity, 0) AS cumulative_quantity,
        (
            SELECT price
            FROM formatted_prices fp
            WHERE fp.ticker = dh.ticker
              AND fp.market_date <= dh.date
            ORDER BY fp.market_date DESC
            LIMIT 1
        ) AS price
    FROM daily_holdings dh
),
holdings_value AS (
    SELECT
        date,
        member_id,
        SUM(cumulative_quantity * price) AS balance
    FROM holdings_with_prices
    WHERE price IS NOT NULL
    GROUP BY date, member_id
),
rolling_averages AS (
    SELECT
        date,
        member_id,
        AVG(balance) OVER (
            PARTITION BY member_id
            ORDER BY date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS average_balance
    FROM holdings_value
),
monthly_max_avg_balances AS (
    SELECT
        strftime('%Y-%m', date) AS Month,
        member_id,
        MAX(average_balance) AS Total_Max_Daily_Avg_Balance
    FROM rolling_averages
    GROUP BY member_id, Month
),
first_month AS (
    SELECT MIN(Month) AS min_month FROM monthly_max_avg_balances
),
result AS (
    SELECT
        Month,
        SUM(Total_Max_Daily_Avg_Balance) AS Total_Max_Daily_Avg_Balance
    FROM monthly_max_avg_balances
    WHERE Month > (SELECT min_month FROM first_month)
    GROUP BY Month
)
SELECT
    Month,
    ROUND(Total_Max_Daily_Avg_Balance, 4) AS Total_Max_Daily_Avg_Balance
FROM result
ORDER BY Month;
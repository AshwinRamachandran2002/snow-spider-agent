WITH first_year_cte AS (
    SELECT MIN(CAST(substr("txn_date", 7, 4) AS INTEGER)) AS "first_year"
    FROM "bitcoin_transactions"
),
yearly_avg_cost AS (
    SELECT
        CAST(substr(bt."txn_date", 7, 4) AS INTEGER) AS "year",
        bm."region",
        AVG(bt."quantity" * bp."price" * (1 + bt."percentage_fee" / 100.0)) AS "average_cost"
    FROM "bitcoin_transactions" bt
    INNER JOIN "bitcoin_prices" bp
        ON bt."ticker" = bp."ticker" AND bt."txn_date" = bp."market_date"
    INNER JOIN "bitcoin_members" bm
        ON bt."member_id" = bm."member_id"
    CROSS JOIN first_year_cte
    WHERE bt."txn_type" = 'BUY' AND CAST(substr(bt."txn_date", 7, 4) AS INTEGER) <> first_year_cte."first_year"
    GROUP BY "year", bm."region"
),
ranked_data AS (
    SELECT
        year,
        region,
        average_cost,
        RANK() OVER (PARTITION BY year ORDER BY average_cost DESC) AS "rank",
        LAG(average_cost) OVER (PARTITION BY region ORDER BY year) AS "prev_average_cost"
    FROM yearly_avg_cost
)
SELECT
    year AS "Year",
    region AS "Region",
    ROUND(average_cost, 4) AS "Average_Cost",
    rank AS "Rank",
    ROUND(((average_cost - prev_average_cost) / prev_average_cost) * 100.0, 4) AS "Annual_Percentage_Change"
FROM ranked_data
ORDER BY year, rank;
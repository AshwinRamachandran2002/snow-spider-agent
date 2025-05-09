WITH monthly_avg_sales AS (
    SELECT
        ym.calendar_month_number AS month,
        AVG(ym.monthly_sales) AS avg_monthly_sales_euros
    FROM (
        SELECT
            t.calendar_year,
            t.calendar_month_number,
            SUM(s.amount_sold) AS monthly_sales
        FROM "sales" s
        JOIN "customers" c ON s.cust_id = c.cust_id
        JOIN "countries" co ON c.country_id = co.country_id
        JOIN "times" t ON s.time_id = t.time_id
        WHERE co.country_name = 'France'
          AND t.calendar_year IN (2019, 2020)
        GROUP BY t.calendar_year, t.calendar_month_number
    ) ym
    GROUP BY ym.calendar_month_number
),
monthly_exchange_rates AS (
    SELECT month, to_us
    FROM "currency"
    WHERE country = 'France' AND year = 2021
),
projected_sales_usd AS (
    SELECT
        ma.month,
        ma.avg_monthly_sales_euros * COALESCE(c.to_us, 1) AS projected_monthly_sales_usd
    FROM monthly_avg_sales ma
    LEFT JOIN monthly_exchange_rates c ON ma.month = c.month
)
SELECT
    AVG(projected_monthly_sales_usd) AS "Average_Monthly_Projected_Sales_in_USD"
FROM projected_sales_usd;
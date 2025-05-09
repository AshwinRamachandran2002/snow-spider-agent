WITH
france_customers AS (
    SELECT c.cust_id
    FROM customers c
    JOIN countries cn ON c.country_id = cn.country_id
    WHERE cn.country_name = 'France'
),
sales_2019 AS (
    SELECT t.calendar_month_number AS month, AVG(s.amount_sold) AS avg_sales_2019
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    WHERE s.cust_id IN (SELECT cust_id FROM france_customers)
      AND t.calendar_year = 2019
    GROUP BY t.calendar_month_number
),
sales_2020 AS (
    SELECT t.calendar_month_number AS month, AVG(s.amount_sold) AS avg_sales_2020
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    WHERE s.cust_id IN (SELECT cust_id FROM france_customers)
      AND t.calendar_year = 2020
    GROUP BY t.calendar_month_number
),
projected_growth AS (
    SELECT
        s19.month,
        s19.avg_sales_2019,
        s20.avg_sales_2020,
        CASE
            WHEN s19.avg_sales_2019 = 0 THEN 0
            ELSE (s20.avg_sales_2020 - s19.avg_sales_2019) / s19.avg_sales_2019
        END AS growth_rate
    FROM sales_2019 s19
    JOIN sales_2020 s20 ON s19.month = s20.month
),
projected_2021 AS (
    SELECT
        month,
        avg_sales_2020 * (1 + growth_rate) AS projected_avg_sales_2021
    FROM projected_growth
),
ordered_projection AS (
    SELECT projected_avg_sales_2021
    FROM projected_2021
    ORDER BY projected_avg_sales_2021
),
median_calc AS (
    SELECT projected_avg_sales_2021
    FROM ordered_projection
    LIMIT 2 OFFSET 5
)
SELECT
    AVG(projected_avg_sales_2021) AS Median_average_monthly_projected_sales_USD
FROM median_calc;
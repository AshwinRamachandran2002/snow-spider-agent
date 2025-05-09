WITH 
products_with_promotions AS (
    SELECT DISTINCT s.prod_id
    FROM sales s
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    JOIN times t ON s.time_id = t.time_id
    WHERE co.country_iso_code = 'US'
      AND t.calendar_year IN (2019, 2020)
      AND t.calendar_quarter_number = 4
      AND s.promo_id <> 999
),
products_with_no_promotions AS (
    SELECT DISTINCT s.prod_id
    FROM sales s
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    JOIN times t ON s.time_id = t.time_id
    WHERE co.country_iso_code = 'US'
      AND t.calendar_year IN (2019, 2020)
      AND t.calendar_quarter_number = 4
      AND s.promo_id = 999
      AND s.prod_id NOT IN (SELECT prod_id FROM products_with_promotions)
),
q4_2019_sales AS (
    SELECT s.prod_id, SUM(s.amount_sold) AS total_sales_2019
    FROM sales s
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    JOIN times t ON s.time_id = t.time_id
    WHERE co.country_iso_code = 'US'
      AND t.calendar_year = 2019
      AND t.calendar_quarter_number = 4
      AND s.promo_id = 999
      AND s.prod_id IN (SELECT prod_id FROM products_with_no_promotions)
    GROUP BY s.prod_id
),
q4_2020_sales AS (
    SELECT s.prod_id, SUM(s.amount_sold) AS total_sales_2020
    FROM sales s
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    JOIN times t ON s.time_id = t.time_id
    WHERE co.country_iso_code = 'US'
      AND t.calendar_year = 2020
      AND t.calendar_quarter_number = 4
      AND s.promo_id = 999
      AND s.prod_id IN (SELECT prod_id FROM products_with_no_promotions)
    GROUP BY s.prod_id
),
total_sales_2019 AS (
    SELECT SUM(total_sales_2019) AS total_2019_sales FROM q4_2019_sales
),
total_sales_2020 AS (
    SELECT SUM(total_sales_2020) AS total_2020_sales FROM q4_2020_sales
),
product_sales_in_2020 AS (
    SELECT prod_id, total_sales_2020
    FROM q4_2020_sales
),
num_products AS (
    SELECT COUNT(*) AS total_products FROM product_sales_in_2020
),
limit_value AS (
    SELECT MAX(1, CAST((total_products * 0.2) AS INTEGER)) AS limit_value FROM num_products
),
top_products AS (
    SELECT prod_id
    FROM product_sales_in_2020
    ORDER BY total_sales_2020 DESC
    LIMIT (SELECT limit_value FROM limit_value)
),
sales_shares AS (
    SELECT
        tp.prod_id,
        COALESCE(q19.total_sales_2019, 0) AS total_sales_2019,
        COALESCE(q20.total_sales_2020, 0) AS total_sales_2020
    FROM top_products tp
    LEFT JOIN q4_2019_sales q19 ON tp.prod_id = q19.prod_id
    LEFT JOIN q4_2020_sales q20 ON tp.prod_id = q20.prod_id
)
SELECT
    ss.prod_id,
    p.prod_name,
    ROUND(ss.total_sales_2019 / (SELECT total_2019_sales FROM total_sales_2019), 4) AS Q4_2019_Sales_Share,
    ROUND(ss.total_sales_2020 / (SELECT total_2020_sales FROM total_sales_2020), 4) AS Q4_2020_Sales_Share,
    ROUND(
        (ss.total_sales_2020 / (SELECT total_2020_sales FROM total_sales_2020)) - 
        (ss.total_sales_2019 / (SELECT total_2019_sales FROM total_sales_2019)), 4
    ) AS Change_in_Sales_Share
FROM sales_shares ss
JOIN products p ON ss.prod_id = p.prod_id
ORDER BY Change_in_Sales_Share DESC;
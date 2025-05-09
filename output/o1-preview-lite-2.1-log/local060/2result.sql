WITH
promo_products AS (
    SELECT DISTINCT s.prod_id
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    WHERE
        ((t.calendar_year = 2019 AND t.calendar_quarter_number = 4) OR
         (t.calendar_year = 2020 AND t.calendar_quarter_number = 4))
        AND s.promo_id != 999
),
products_no_promos AS (
    SELECT s.prod_id
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    WHERE
        ((t.calendar_year = 2019 AND t.calendar_quarter_number = 4) OR
         (t.calendar_year = 2020 AND t.calendar_quarter_number = 4))
    GROUP BY s.prod_id
    HAVING MIN(s.promo_id) = 999 AND MAX(s.promo_id) = 999
),
total_sales_per_product AS (
    SELECT s.prod_id, SUM(s.amount_sold) AS total_sales
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    WHERE
        co.country_name = 'United States of America'
        AND ((t.calendar_year = 2019 AND t.calendar_quarter_number = 4) OR
             (t.calendar_year = 2020 AND t.calendar_quarter_number = 4))
        AND s.prod_id IN (SELECT prod_id FROM products_no_promos)
        AND s.promo_id = 999
    GROUP BY s.prod_id
),
product_ranks AS (
    SELECT s.prod_id, s.total_sales,
        (SELECT COUNT(*) + 1 FROM total_sales_per_product s2 WHERE s2.total_sales > s.total_sales) AS rank,
        (SELECT COUNT(*) FROM total_sales_per_product) AS total_products
    FROM total_sales_per_product s
),
top_20_percent_products AS (
    SELECT pr.prod_id
    FROM product_ranks pr
    WHERE pr.rank <= (pr.total_products * 0.2)
),
product_sales_shares AS (
    SELECT
        s.prod_id,
        p.prod_name,
        SUM(CASE WHEN t.calendar_year = 2019 THEN s.amount_sold ELSE 0 END) AS Q4_2019_Sales,
        SUM(CASE WHEN t.calendar_year = 2020 THEN s.amount_sold ELSE 0 END) AS Q4_2020_Sales
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries co ON c.country_id = co.country_id
    JOIN products p ON s.prod_id = p.prod_id
    WHERE
        co.country_name = 'United States of America'
        AND ((t.calendar_year = 2019 AND t.calendar_quarter_number = 4) OR
             (t.calendar_year = 2020 AND t.calendar_quarter_number = 4))
        AND s.promo_id = 999
        AND s.prod_id IN (SELECT prod_id FROM top_20_percent_products)
    GROUP BY s.prod_id, p.prod_name
),
total_sales_2019 AS (
    SELECT SUM(Q4_2019_Sales) AS total_2019_sales FROM product_sales_shares
),
total_sales_2020 AS (
    SELECT SUM(Q4_2020_Sales) AS total_2020_sales FROM product_sales_shares
),
final_result AS (
    SELECT
        ps.prod_id AS Product_ID,
        ps.prod_name AS Product_Name,
        ROUND(ps.Q4_2019_Sales / (SELECT total_2019_sales FROM total_sales_2019), 4) AS Q4_2019_Sales_Share,
        ROUND(ps.Q4_2020_Sales / (SELECT total_2020_sales FROM total_sales_2020), 4) AS Q4_2020_Sales_Share,
        ROUND((ps.Q4_2020_Sales / (SELECT total_2020_sales FROM total_sales_2020)) - (ps.Q4_2019_Sales / (SELECT total_2019_sales FROM total_sales_2019)), 4) AS Change_in_Sales_Share
    FROM product_sales_shares ps
)
SELECT
    Product_ID,
    Product_Name,
    Q4_2019_Sales_Share,
    Q4_2020_Sales_Share,
    Change_in_Sales_Share
FROM final_result
ORDER BY Change_in_Sales_Share DESC;
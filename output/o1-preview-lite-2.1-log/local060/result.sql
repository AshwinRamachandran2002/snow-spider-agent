SELECT
  tp.prod_id AS "Product_ID",
  p.prod_name AS "Product_Name",
  ROUND(tp.share_2019, 4) AS "Q4_2019_Sales_Share",
  ROUND(tp.share_2020, 4) AS "Q4_2020_Sales_Share",
  ROUND(tp.change_in_share, 4) AS "Change_in_Sales_Share"
FROM (
  WITH promoted_products AS (
    SELECT DISTINCT s.prod_id
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries cn ON c.country_id = cn.country_id
    WHERE cn.country_name = 'United States of America'
      AND s.promo_id != 999
      AND (
        (t.calendar_year = 2019 AND t.calendar_month_number BETWEEN 10 AND 12)
        OR
        (t.calendar_year = 2020 AND t.calendar_month_number BETWEEN 10 AND 12)
      )
  ),
  sales_data AS (
    SELECT s.prod_id,
           SUM(CASE WHEN t.calendar_year = 2019 THEN s.amount_sold ELSE 0 END) AS amount_sold_2019,
           SUM(CASE WHEN t.calendar_year = 2020 THEN s.amount_sold ELSE 0 END) AS amount_sold_2020
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN customers c ON s.cust_id = c.cust_id
    JOIN countries cn ON c.country_id = cn.country_id
    WHERE cn.country_name = 'United States of America'
      AND s.promo_id = 999
      AND s.prod_id NOT IN (SELECT prod_id FROM promoted_products)
      AND t.calendar_year IN (2019, 2020)
      AND t.calendar_month_number BETWEEN 10 AND 12
    GROUP BY s.prod_id
  ),
  total_sales AS (
    SELECT
      SUM(amount_sold_2019) AS sum_sales_2019,
      SUM(amount_sold_2020) AS sum_sales_2020
    FROM sales_data
  ),
  product_shares AS (
    SELECT
      sd.prod_id,
      sd.amount_sold_2019,
      sd.amount_sold_2020,
      (sd.amount_sold_2019 + sd.amount_sold_2020) AS total_sales_both,
      sd.amount_sold_2019 / ts.sum_sales_2019 AS share_2019,
      sd.amount_sold_2020 / ts.sum_sales_2020 AS share_2020,
      (sd.amount_sold_2020 / ts.sum_sales_2020) - (sd.amount_sold_2019 / ts.sum_sales_2019) AS change_in_share
    FROM sales_data sd
    CROSS JOIN total_sales ts
  ),
  product_ranked AS (
    SELECT
      ps.*,
      ROW_NUMBER() OVER (ORDER BY ps.total_sales_both DESC) AS rn,
      (SELECT COUNT(*) FROM product_shares) AS total_products
    FROM product_shares ps
  ),
  top_products AS (
    SELECT *, CAST(total_products * 0.2 AS INT) AS top_N
    FROM product_ranked
    WHERE rn <= CAST(total_products * 0.2 AS INT)
  )
  SELECT *
  FROM top_products
) tp
JOIN products p ON tp.prod_id = p.prod_id
ORDER BY tp.change_in_share DESC;
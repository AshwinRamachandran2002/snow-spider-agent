WITH avg_wholesale AS (
  SELECT 
    w.item_code,
    substr(w."whsle_date", 1, 4) AS year,
    AVG(w."whsle_px_rmb-kg") AS avg_wholesale_price,
    MAX(w."whsle_px_rmb-kg") AS max_wholesale_price,
    MIN(w."whsle_px_rmb-kg") AS min_wholesale_price
  FROM "veg_whsle_df" w
  WHERE substr(w."whsle_date", 1, 4) BETWEEN '2020' AND '2023'
  GROUP BY w.item_code, year
),
total_sales AS (
  SELECT 
    t.item_code,
    substr(t."txn_date", 1, 4) AS year,
    SUM(t."qty_sold(kg)") AS total_qty_sold,
    AVG(t."unit_selling_px_rmb/kg") AS avg_selling_price_per_kg
  FROM "veg_txn_df" t
  WHERE t."sale/return" = 'sale' AND substr(t."txn_date", 1, 4) BETWEEN '2020' AND '2023'
  GROUP BY t.item_code, year
),
avg_loss_rate AS (
  SELECT l.item_code, AVG(l."loss_rate_%") AS avg_loss_rate
  FROM "veg_loss_rate_df" l
  GROUP BY l.item_code
),
item_categories AS (
  SELECT DISTINCT item_code, category_name
  FROM "veg_cat"
),
combined AS (
  SELECT
    a.item_code,
    a.year,
    c.category_name,
    ts.total_qty_sold,
    a.avg_wholesale_price,
    a.max_wholesale_price,
    a.min_wholesale_price,
    ts.avg_selling_price_per_kg,
    COALESCE(al.avg_loss_rate, 0) AS avg_loss_rate
  FROM avg_wholesale a
  JOIN total_sales ts ON a.item_code = ts.item_code AND a.year = ts.year
  LEFT JOIN avg_loss_rate al ON a.item_code = al.item_code
  LEFT JOIN item_categories c ON a.item_code = c.item_code
  WHERE c.category_name IS NOT NULL
)
SELECT 
  c.year AS "Year",
  c.category_name AS "Category",
  ROUND(SUM(c.total_qty_sold * c.avg_wholesale_price) / SUM(c.total_qty_sold), 2) AS "Average_Wholesale_Price",
  ROUND(MAX(c.max_wholesale_price), 2) AS "Maximum_Wholesale_Price",
  ROUND(MIN(c.min_wholesale_price), 2) AS "Minimum_Wholesale_Price",
  ROUND(MAX(c.max_wholesale_price) - MIN(c.min_wholesale_price), 2) AS "Wholesale_Price_Difference",
  ROUND(SUM(c.total_qty_sold * c.avg_wholesale_price), 2) AS "Total_Wholesale_Price",
  ROUND(SUM(c.total_qty_sold * c.avg_selling_price_per_kg), 2) AS "Total_Selling_Price",
  ROUND(AVG(c.avg_loss_rate), 2) AS "Average_Loss_Rate",
  ROUND(SUM(c.total_qty_sold * c.avg_wholesale_price * c.avg_loss_rate / 100), 2) AS "Total_Loss",
  ROUND(SUM(c.total_qty_sold * c.avg_selling_price_per_kg) - SUM(c.total_qty_sold * c.avg_wholesale_price) - SUM(c.total_qty_sold * c.avg_wholesale_price * c.avg_loss_rate / 100), 2) AS "Profit"
FROM combined c
GROUP BY c.year, c.category_name
ORDER BY c.year, c.category_name;
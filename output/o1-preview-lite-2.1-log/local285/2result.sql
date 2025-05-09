WITH whsle AS (
  SELECT 
    w."item_code", 
    strftime('%Y', w."whsle_date") AS "Year", 
    AVG(w."whsle_px_rmb-kg") AS "Avg_Wholesale_Price",
    MAX(w."whsle_px_rmb-kg") AS "Max_Wholesale_Price",
    MIN(w."whsle_px_rmb-kg") AS "Min_Wholesale_Price"
  FROM "veg_whsle_df" w
  WHERE strftime('%Y', w."whsle_date") BETWEEN '2020' AND '2023'
  GROUP BY w."item_code", "Year"
),
txn AS (
  SELECT 
    t."item_code", 
    strftime('%Y', t."txn_date") AS "Year",
    SUM(t."qty_sold(kg)") AS "Total_Qty_Sold",
    SUM(t."unit_selling_px_rmb/kg" * t."qty_sold(kg)") AS "Total_Selling_Price"
  FROM "veg_txn_df" t
  WHERE strftime('%Y', t."txn_date") BETWEEN '2020' AND '2023'
  GROUP BY t."item_code", "Year"
),
loss AS (
  SELECT 
    l."item_code", 
    l."loss_rate_%"
  FROM "veg_loss_rate_df" l
),
cat AS (
  SELECT 
    c."item_code", 
    c."category_name" AS "Category"
  FROM "veg_cat" c
)
SELECT
  whsle."Year",
  cat."Category",
  ROUND(AVG(whsle."Avg_Wholesale_Price"), 2) AS "Average_Wholesale_Price",
  ROUND(MAX(whsle."Max_Wholesale_Price"), 2) AS "Maximum_Wholesale_Price",
  ROUND(MIN(whsle."Min_Wholesale_Price"), 2) AS "Minimum_Wholesale_Price",
  ROUND(MAX(whsle."Max_Wholesale_Price") - MIN(whsle."Min_Wholesale_Price"), 2) AS "Wholesale_Price_Difference",
  ROUND(SUM(whsle."Avg_Wholesale_Price" * txn."Total_Qty_Sold"), 2) AS "Total_Wholesale_Price",
  ROUND(SUM(txn."Total_Selling_Price"), 2) AS "Total_Selling_Price",
  ROUND(AVG(loss."loss_rate_%"), 2) AS "Average_Loss_Rate",
  ROUND(SUM((whsle."Avg_Wholesale_Price" * txn."Total_Qty_Sold") * (loss."loss_rate_%" / 100)), 2) AS "Total_Loss",
  ROUND(SUM(txn."Total_Selling_Price" - (whsle."Avg_Wholesale_Price" * txn."Total_Qty_Sold") - ((whsle."Avg_Wholesale_Price" * txn."Total_Qty_Sold") * (loss."loss_rate_%" / 100))), 2) AS "Profit"
FROM whsle
JOIN txn ON whsle."item_code" = txn."item_code" AND whsle."Year" = txn."Year"
JOIN loss ON whsle."item_code" = loss."item_code"
JOIN cat ON whsle."item_code" = cat."item_code"
GROUP BY whsle."Year", cat."Category"
ORDER BY whsle."Year", cat."Category";
WITH
WholesaleStats AS (
  SELECT
    c."category_name" AS "Category_Name",
    EXTRACT(YEAR FROM TO_DATE(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
    ROUND(AVG(w."whsle_px_rmb-kg"), 4) AS "Avg_Wholesale_Price",
    ROUND(MAX(w."whsle_px_rmb-kg"), 4) AS "Max_Wholesale_Price",
    ROUND(MIN(w."whsle_px_rmb-kg"), 4) AS "Min_Wholesale_Price",
    ROUND(MAX(w."whsle_px_rmb-kg") - MIN(w."whsle_px_rmb-kg"), 4) AS "Wholesale_Price_Diff"
  FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF AS w
  JOIN
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT AS c
    ON w."item_code" = c."item_code"
  WHERE
    w."whsle_date" >= '2020-01-01' AND w."whsle_date" <= '2023-12-31'
  GROUP BY
    c."category_name",
    EXTRACT(YEAR FROM TO_DATE(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS'))
),
FinancialStats AS (
  SELECT
    c."category_name" AS "Category_Name",
    EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'YYYY-MM-DD HH24:MI:SS')) AS "Year",
    ROUND(SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg"), 4) AS "Total_Wholesale_Price",
    ROUND(SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"), 4) AS "Total_Selling_Price",
    ROUND(AVG(l."loss_rate_%"), 4) AS "Avg_Loss_Rate",
    ROUND(SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg" * (l."loss_rate_%" / 100)), 4) AS "Total_Loss",
    ROUND(
      SUM(t."qty_sold(kg)" * t."unit_selling_px_rmb/kg")
      - SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg")
      - SUM(t."qty_sold(kg)" * w."whsle_px_rmb-kg" * (l."loss_rate_%" / 100))
    , 4) AS "Profit"
  FROM
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF AS t
  JOIN
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF AS w
    ON t."item_code" = w."item_code"
    AND TO_DATE(t."txn_date", 'YYYY-MM-DD HH24:MI:SS') = TO_DATE(w."whsle_date", 'YYYY-MM-DD HH24:MI:SS')
  JOIN
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF AS l
    ON t."item_code" = l."item_code"
  JOIN
    BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT AS c
    ON t."item_code" = c."item_code"
  WHERE
    LOWER(t."sale/return") = 'sale'
    AND t."txn_date" >= '2020-01-01' AND t."txn_date" <= '2023-12-31'
  GROUP BY
    c."category_name",
    EXTRACT(YEAR FROM TO_DATE(t."txn_date", 'YYYY-MM-DD HH24:MI:SS'))
)
SELECT
  ws."Category_Name",
  ws."Year",
  ws."Avg_Wholesale_Price",
  ws."Max_Wholesale_Price",
  ws."Min_Wholesale_Price",
  ws."Wholesale_Price_Diff",
  fs."Total_Wholesale_Price",
  fs."Total_Selling_Price",
  fs."Avg_Loss_Rate",
  fs."Total_Loss",
  fs."Profit"
FROM
  WholesaleStats ws
JOIN
  FinancialStats fs
  ON ws."Category_Name" = fs."Category_Name" AND ws."Year" = fs."Year"
ORDER BY
  ws."Category_Name", ws."Year";
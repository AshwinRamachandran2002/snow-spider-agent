WITH
wholesale AS (
    SELECT 
        substr(w."whsle_date",1,4)                    AS year,
        c."category_name"                             AS category,
        w."whsle_px_rmb-kg"                           AS price
    FROM "veg_whsle_df" w
    JOIN "veg_cat" c USING ("item_code")
    WHERE substr(w."whsle_date",1,4) BETWEEN '2020' AND '2023'
),
wholesale_agg AS (
    SELECT
        year,
        category,
        ROUND(AVG(price),2)                           AS avg_wholesale_price,
        ROUND(MAX(price),2)                           AS max_wholesale_price,
        ROUND(MIN(price),2)                           AS min_wholesale_price,
        ROUND(MAX(price) - MIN(price),2)              AS wholesale_price_difference,
        ROUND(SUM(price),2)                           AS total_wholesale_price
    FROM wholesale
    GROUP BY year, category
),
sales AS (
    SELECT
        substr(t."txn_date",1,4)                      AS year,
        c."category_name"                             AS category,
        t."unit_selling_px_rmb/kg" * 
        t."qty_sold(kg)"                              AS sales_value
    FROM "veg_txn_df" t
    JOIN "veg_cat" c USING ("item_code")
    WHERE substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
      AND t."sale/return" = 'sale'
),
sales_agg AS (
    SELECT
        year,
        category,
        ROUND(SUM(sales_value),2)                     AS total_selling_price
    FROM sales
    GROUP BY year, category
),
loss_rate AS (
    SELECT
        c."category_name"                             AS category,
        AVG(l."loss_rate_%")/100.0                    AS loss_rate
    FROM "veg_loss_rate_df" l
    JOIN "veg_cat" c USING ("item_code")
    GROUP BY category
),
loss_value AS (
    SELECT
        substr(t."txn_date",1,4)                      AS year,
        c."category_name"                             AS category,
        t."unit_selling_px_rmb/kg" * 
        t."qty_sold(kg)" * (l."loss_rate_%"/100.0)    AS loss_val
    FROM "veg_txn_df" t
    JOIN "veg_cat" c USING ("item_code")
    JOIN "veg_loss_rate_df" l USING ("item_code")
    WHERE substr(t."txn_date",1,4) BETWEEN '2020' AND '2023'
      AND t."sale/return" = 'sale'
),
loss_agg AS (
    SELECT
        year,
        category,
        ROUND(SUM(loss_val),2)                        AS total_loss
    FROM loss_value
    GROUP BY year, category
)
SELECT
    w.year,
    w.category,
    w.avg_wholesale_price,
    w.max_wholesale_price,
    w.min_wholesale_price,
    w.wholesale_price_difference,
    w.total_wholesale_price,
    s.total_selling_price,
    ROUND(lr.loss_rate*100,2)                        AS avg_loss_rate,
    l.total_loss,
    ROUND(s.total_selling_price - 
          w.total_wholesale_price - 
          l.total_loss,2)                            AS profit
FROM wholesale_agg w
JOIN sales_agg  s  USING (year, category)
JOIN loss_agg   l  USING (year, category)
JOIN loss_rate  lr USING (category)
ORDER BY w.year, w.category;
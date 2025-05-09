WITH sale_txns AS (        -- total quantity sold and revenue per item & year
    SELECT
        SUBSTR("txn_date",1,4)              AS year,
        "item_code",
        SUM("qty_sold(kg)")                 AS qty_sold,
        SUM("qty_sold(kg)" * "unit_selling_px_rmb/kg") AS revenue
    FROM veg_txn_df
    WHERE LOWER("sale/return") = 'sale'
      AND CAST(SUBSTR("txn_date",1,4) AS INTEGER) BETWEEN 2020 AND 2023
    GROUP BY year, "item_code"
),
wholesale_stats AS (       -- wholesale‑price statistics per item & year
    SELECT
        SUBSTR("whsle_date",1,4)            AS year,
        "item_code",
        AVG("whsle_px_rmb-kg")              AS avg_whsle_price,
        MAX("whsle_px_rmb-kg")              AS max_whsle_price_item,
        MIN("whsle_px_rmb-kg")              AS min_whsle_price_item
    FROM veg_whsle_df
    WHERE CAST(SUBSTR("whsle_date",1,4) AS INTEGER) BETWEEN 2020 AND 2023
    GROUP BY year, "item_code"
),
item_level AS (            -- merge sales with wholesale & loss data
    SELECT
        s.year,
        s."item_code",
        s.qty_sold,
        s.revenue,
        w.avg_whsle_price,
        w.max_whsle_price_item,
        w.min_whsle_price_item,
        COALESCE(l."loss_rate_%",0) AS loss_rate
    FROM sale_txns        AS s
    JOIN wholesale_stats  AS w  ON w.year = s.year AND w."item_code" = s."item_code"
    LEFT JOIN veg_loss_rate_df AS l ON l."item_code" = s."item_code"
),
item_costs AS (            -- compute costs and losses per item & year
    SELECT
        i.*,
        (i.qty_sold * i.avg_whsle_price)                        AS wholesale_cost,
        (i.qty_sold * i.avg_whsle_price) * i.loss_rate/100.0   AS loss_value
    FROM item_level i
),
item_with_cat AS (         -- attach category name
    SELECT
        c.category_name,
        ic.*
    FROM item_costs  ic
    LEFT JOIN veg_cat AS c
           ON c."item_code" = ic."item_code"
    WHERE c.category_name IS NOT NULL
),
category_year AS (         -- aggregate to category–year level
    SELECT
        year,
        category_name,
        ROUND(AVG(avg_whsle_price),2)                  AS average_wholesale_price,
        ROUND(MAX(max_whsle_price_item),2)             AS max_wholesale_price,
        ROUND(MIN(min_whsle_price_item),2)             AS min_wholesale_price,
        ROUND(MAX(max_whsle_price_item) - MIN(min_whsle_price_item),2)
                                                      AS wholesale_price_difference,
        ROUND(SUM(wholesale_cost),2)                  AS total_wholesale_price,
        ROUND(SUM(revenue),2)                         AS total_selling_price,
        ROUND(AVG(loss_rate),2)                       AS average_loss_rate,
        ROUND(SUM(loss_value),2)                      AS total_loss,
        ROUND(SUM(revenue) - SUM(wholesale_cost) - SUM(loss_value),2)
                                                      AS profit
    FROM item_with_cat
    GROUP BY year, category_name
)
SELECT
    year,
    category_name,
    average_wholesale_price,
    max_wholesale_price,
    min_wholesale_price,
    wholesale_price_difference,
    total_wholesale_price,
    total_selling_price,
    average_loss_rate,
    total_loss,
    profit
FROM category_year
ORDER BY year, category_name;
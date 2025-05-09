WITH
-- 1. join each vegetable sale with the matching wholesale price (same item, same calendar day)
txn_whsle AS (
    SELECT
        t."item_code",
        strftime('%Y', t."txn_date")        AS yr,
        t."qty_sold(kg)"                    AS qty_kg,
        t."unit_selling_px_rmb/kg"          AS sell_px,
        w."whsle_px_rmb-kg"                 AS whsle_px
    FROM veg_txn_df  AS t
    JOIN veg_whsle_df AS w
          ON  t."item_code" = w."item_code"
          AND date(t."txn_date") = date(w."whsle_date")
    WHERE strftime('%Y', t."txn_date") BETWEEN '2020' AND '2023'
),

-- 2. aggregate at item‑year level
item_year AS (
    SELECT
        "item_code",
        yr,
        SUM(qty_kg * whsle_px)             AS total_whsle_val,
        SUM(qty_kg * sell_px)              AS total_sell_val,
        AVG(whsle_px)                      AS avg_whsle_px,
        MAX(whsle_px)                      AS max_whsle_px,
        MIN(whsle_px)                      AS min_whsle_px
    FROM txn_whsle
    GROUP BY "item_code", yr
),

-- 3. append loss rate for each item
item_year_loss AS (
    SELECT
        iy.*,
        COALESCE(l."loss_rate_%", 0) AS loss_rate_pct
    FROM item_year          AS iy
    LEFT JOIN veg_loss_rate_df AS l
           ON iy."item_code" = l."item_code"
),

-- 4. roll up to category‑year level and compute requested metrics
cat_year AS (
    SELECT
        c."category_name"                  AS category,
        iy.yr                              AS year,
        ROUND(AVG(iy.avg_whsle_px) , 2)    AS avg_wholesale_price,
        ROUND(MAX(iy.max_whsle_px) , 2)    AS max_wholesale_price,
        ROUND(MIN(iy.min_whsle_px) , 2)    AS min_wholesale_price,
        ROUND(MAX(iy.max_whsle_px) - MIN(iy.min_whsle_px), 2)  AS wholesale_price_diff,
        ROUND(SUM(iy.total_whsle_val) , 2) AS total_wholesale_price,
        ROUND(SUM(iy.total_sell_val)  , 2) AS total_selling_price,
        ROUND(AVG(iy.loss_rate_pct)   , 2) AS avg_loss_rate,
        ROUND(SUM(iy.total_whsle_val * iy.loss_rate_pct/100) , 2) AS total_loss,
        ROUND(  SUM(iy.total_sell_val)
              - SUM(iy.total_whsle_val)
              - SUM(iy.total_whsle_val * iy.loss_rate_pct/100)
        , 2) AS profit
    FROM item_year_loss   AS iy
    JOIN veg_cat          AS c
          ON iy."item_code" = c."item_code"
    GROUP BY category, year
)

SELECT
    category              AS "category_name",
    year,
    avg_wholesale_price,
    max_wholesale_price,
    min_wholesale_price,
    wholesale_price_diff,
    total_wholesale_price,
    total_selling_price,
    avg_loss_rate,
    total_loss,
    profit
FROM cat_year
ORDER BY category_name, year;
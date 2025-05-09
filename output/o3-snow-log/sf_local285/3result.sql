WITH whs AS (   -- 1. wholesale prices with year & category
    SELECT
        TO_CHAR(TO_DATE(w."whsle_date",'YYYY-MM-DD HH24:MI:SS'),'YYYY')          AS "year",
        c."category_name",
        w."whsle_px_rmb-kg"                                                     AS wholesale_price
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_WHSLE_DF  w
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT       c
      ON w."item_code" = c."item_code"
    WHERE TO_CHAR(TO_DATE(w."whsle_date",'YYYY-MM-DD HH24:MI:SS'),'YYYY') 
          BETWEEN '2020' AND '2023'
),  
whs_agg AS (     -- 2. yearly‐category wholesale statistics
    SELECT
        "year",
        "category_name",
        ROUND(AVG(wholesale_price),2)                               AS avg_wholesale_price,
        ROUND(MAX(wholesale_price),2)                               AS max_wholesale_price,
        ROUND(MIN(wholesale_price),2)                               AS min_wholesale_price,
        ROUND(MAX(wholesale_price)-MIN(wholesale_price),2)          AS wholesale_price_difference,
        ROUND(SUM(wholesale_price),2)                               AS total_wholesale_price
    FROM whs
    GROUP BY "year","category_name"
),  
loss AS (        -- 3. average loss rate per category (static table)
    SELECT
        c."category_name",
        ROUND(AVG(l."loss_rate_%"),2)                               AS avg_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF l
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT        c
      ON l."item_code" = c."item_code"
    GROUP BY c."category_name"
),  
sell AS (        -- 4. sales amounts with year & category
    SELECT
        TO_CHAR(TO_DATE(t."txn_date",'YYYY-MM-DD HH24:MI:SS'),'YYYY')            AS "year",
        c."category_name",
        t."qty_sold(kg)" * t."unit_selling_px_rmb/kg"                            AS selling_amount
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_TXN_DF   t
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_CAT      c
      ON t."item_code" = c."item_code"
    WHERE TO_CHAR(TO_DATE(t."txn_date",'YYYY-MM-DD HH24:MI:SS'),'YYYY')
          BETWEEN '2020' AND '2023'
      AND LOWER(t."sale/return") = 'sale'
),  
sell_agg AS (    -- 5. yearly‐category total selling price
    SELECT
        "year",
        "category_name",
        ROUND(SUM(selling_amount),2)                              AS total_selling_price
    FROM sell
    GROUP BY "year","category_name"
)  
-- 6. combine everything & derive profit
SELECT
    w."year",
    w."category_name",
    w.avg_wholesale_price,
    w.max_wholesale_price,
    w.min_wholesale_price,
    w.wholesale_price_difference,
    w.total_wholesale_price,
    COALESCE(s.total_selling_price,0)                                         AS total_selling_price,
    COALESCE(l.avg_loss_rate,0)                                               AS avg_loss_rate,
    ROUND(w.total_wholesale_price * COALESCE(l.avg_loss_rate,0)/100,2)        AS total_loss,
    ROUND( COALESCE(s.total_selling_price,0) 
         - w.total_wholesale_price 
         - w.total_wholesale_price * COALESCE(l.avg_loss_rate,0)/100 , 2)     AS profit
FROM whs_agg w
LEFT JOIN sell_agg s  ON w."year" = s."year" AND w."category_name" = s."category_name"
LEFT JOIN loss     l  ON w."category_name" = l."category_name"
ORDER BY w."year", w."category_name";
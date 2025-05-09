/*  Financial performance for each produce category, 2020‑2023 */
SELECT
        SUBSTR(vw."whsle_date",1,4)                                           AS "year",
        vc."category_name",
        ROUND(AVG(vw."whsle_px_rmb-kg"),2)                                    AS "avg_wholesale_price",
        ROUND(MAX(vw."whsle_px_rmb-kg"),2)                                    AS "max_wholesale_price",
        ROUND(MIN(vw."whsle_px_rmb-kg"),2)                                    AS "min_wholesale_price",
        ROUND(MAX(vw."whsle_px_rmb-kg") - MIN(vw."whsle_px_rmb-kg"),2)        AS "wholesale_price_diff",
        ROUND(SUM(vw."whsle_px_rmb-kg" * vt."qty_sold(kg)"),2)                AS "total_wholesale_cost",
        ROUND(SUM(vt."unit_selling_px_rmb/kg" * vt."qty_sold(kg)"),2)         AS "total_selling_revenue",
        ROUND(AVG(vl."loss_rate_%"),2)                                        AS "avg_loss_rate_pct",
        ROUND(SUM(vt."unit_selling_px_rmb/kg" * vt."qty_sold(kg)" *
                  vl."loss_rate_%"/100),2)                                    AS "total_loss_rmb",
        ROUND(SUM(vt."unit_selling_px_rmb/kg" * vt."qty_sold(kg)")            -- revenue
              - SUM(vw."whsle_px_rmb-kg" * vt."qty_sold(kg)")                 -- wholesale cost
              - SUM(vt."unit_selling_px_rmb/kg" * vt."qty_sold(kg)" *
                    vl."loss_rate_%"/100),2)                                  AS "profit_rmb"
FROM    "veg_whsle_df"          AS vw
JOIN    "veg_txn_df"            AS vt  ON  vw."item_code" = vt."item_code"
                                         AND SUBSTR(vw."whsle_date",1,10) = SUBSTR(vt."txn_date",1,10)
JOIN    "veg_loss_rate_df"      AS vl  ON  vw."item_code" = vl."item_code"
JOIN    "veg_cat"               AS vc  ON  vw."item_code" = vc."item_code"
WHERE   SUBSTR(vw."whsle_date",1,4) BETWEEN '2020' AND '2023'
GROUP BY "year", vc."category_name"
ORDER BY "year", vc."category_name";
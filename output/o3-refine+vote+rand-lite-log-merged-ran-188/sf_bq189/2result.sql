WITH completed_items AS (
    /* all items that were actually completed, enriched with product category
       and the month (first day of month) in which the item was created       */
    SELECT
        oi."order_id",
        p."category"                                            AS "category",
        oi."sale_price"                                         AS "sale_price",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "order_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
), monthly_stats AS (
    /* for every category & month:
         – distinct completed orders
         – revenue of those orders                                    */
    SELECT
        "category",
        "order_month",
        COUNT(DISTINCT "order_id")          AS "order_cnt",
        SUM("sale_price")                   AS "revenue"
    FROM completed_items
    GROUP BY
        "category",
        "order_month"
), monthly_growth AS (
    /* calculate month‑over‑month % growth of order count & revenue   */
    SELECT
        "category",
        "order_month",
        "order_cnt",
        "revenue",
        /* previous month metrics */
        LAG("order_cnt")  OVER (PARTITION BY "category" ORDER BY "order_month")   AS "prev_order_cnt",
        LAG("revenue")    OVER (PARTITION BY "category" ORDER BY "order_month")   AS "prev_revenue"
    FROM monthly_stats
), growth_rates AS (
    /* percentage growth; skip months where previous value = 0 or NULL */
    SELECT
        "category",
        CASE
            WHEN "prev_order_cnt"  > 0 THEN 
                 (("order_cnt" - "prev_order_cnt")::FLOAT)  / "prev_order_cnt"
        END                                       AS "order_growth_pct",
        CASE
            WHEN "prev_revenue"    > 0 THEN 
                 (("revenue"   - "prev_revenue")  ::FLOAT)  / "prev_revenue"
        END                                       AS "revenue_growth_pct"
    FROM monthly_growth
), avg_order_growth AS (
    /* average monthly order‑count growth per category                 */
    SELECT
        "category",
        AVG("order_growth_pct")   AS "avg_order_growth_pct"
    FROM growth_rates
    GROUP BY "category"
), top_category AS (
    /* pick the category with the highest average order growth         */
    SELECT
        "category",
        "avg_order_growth_pct"
    FROM avg_order_growth
    ORDER BY "avg_order_growth_pct" DESC NULLS LAST
    LIMIT 1
), avg_revenue_growth_for_top AS (
    /* for that category, compute the average monthly revenue growth   */
    SELECT
        tc."category",
        tc."avg_order_growth_pct",
        AVG(gr."revenue_growth_pct")  AS "avg_revenue_growth_pct"
    FROM top_category tc
    JOIN growth_rates  gr
          ON gr."category" = tc."category"
    GROUP BY
        tc."category",
        tc."avg_order_growth_pct"
)
SELECT
    "category"                        AS "product_category_with_highest_avg_order_growth",
    "avg_order_growth_pct"            AS "avg_monthly_order_growth_pct",
    "avg_revenue_growth_pct"          AS "avg_monthly_revenue_growth_pct"
FROM avg_revenue_growth_for_top;
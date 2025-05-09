/*-----------------------------------------------------------
  1) Pull every 30-Nov-2020 purchase row and explode its ITEMS
     array so we know which item_category appears in each order.
  2) Work out each category’s overall tax-rate
         ( Σ tax_value_in_usd ÷ Σ purchase_revenue_in_usd ).
  3) Keep the single category with the highest tax-rate.
  4) Return every purchase that contains that top-tax-rate
     category, showing the required revenue and quantity fields.
-----------------------------------------------------------*/
WITH item_purchases AS (
    SELECT
        /*  Purchase–level metrics pulled from the ECOMMERCE JSON  */
        t."ECOMMERCE":"tax_value_in_usd"        ::FLOAT   AS tax_usd,
        t."ECOMMERCE":"purchase_revenue_in_usd" ::FLOAT   AS revenue_usd,
        t."ECOMMERCE":"purchase_revenue"        ::FLOAT   AS purchase_revenue,
        t."ECOMMERCE":"total_item_quantity"     ::NUMBER  AS total_item_quantity,
        t."ECOMMERCE":"transaction_id"          ::STRING  AS transaction_id,
        /*  Item-level dimension coming from the ITEMS array       */
        fi.value:"item_category"                ::STRING  AS item_category
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130" t,
         LATERAL FLATTEN(input => t."ITEMS") fi
    WHERE t."EVENT_NAME" = 'purchase'
),
top_category AS (
    SELECT item_category
    FROM   item_purchases
    GROUP  BY item_category
    ORDER  BY SUM(tax_usd) / NULLIF(SUM(revenue_usd),0) DESC NULLS LAST
    LIMIT 1
)
SELECT DISTINCT
       ip.transaction_id,
       ip.total_item_quantity,
       ip.revenue_usd        AS purchase_revenue_in_usd,
       ip.purchase_revenue
FROM   item_purchases ip
JOIN   top_category  tc
       ON ip.item_category = tc.item_category
ORDER  BY ip.transaction_id;
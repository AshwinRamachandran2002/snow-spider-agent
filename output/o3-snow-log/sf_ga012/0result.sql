/*------------------------------------------------------------
  1)  Work out the item_category whose tax-to-revenue ratio is
      the highest on 30-Nov-2020 purchase events.

  2)  For every purchase event that contains at least one item
      in that top-tax-rate category, return:
          • the GA transaction_id
          • total quantity of items in the basket
          • purchase revenue in USD        (param  = 'value')
          • purchase revenue (native)      (sum of item_revenue)
------------------------------------------------------------*/
WITH category_tax AS (   -- total tax and revenue per category
    SELECT
        i.value:"item_category"::STRING                                                  AS item_category,
        SUM( CASE WHEN ep_tax.value:"key"::STRING = 'tax'
                  THEN ep_tax.value:"value":"double_value"::FLOAT END )                  AS total_tax_usd,
        SUM( CASE WHEN ep_val.value:"key"::STRING = 'value'
                  THEN ep_val.value:"value":"double_value"::FLOAT END )                  AS purchase_revenue_usd
    FROM   GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"   e
           , LATERAL FLATTEN( input => e."ITEMS")                  i
           , LATERAL FLATTEN( input => e."EVENT_PARAMS")           ep_tax
           , LATERAL FLATTEN( input => e."EVENT_PARAMS")           ep_val
    WHERE  e."EVENT_NAME" = 'purchase'
      AND  ep_tax.value:"key"::STRING = 'tax'
      AND  ep_val.value:"key"::STRING = 'value'
    GROUP  BY 1
),
top_category AS (        -- keep only the category with the highest tax rate
    SELECT  item_category
    FROM    category_tax
    QUALIFY ROW_NUMBER() OVER (ORDER BY
              total_tax_usd / NULLIF(purchase_revenue_usd,0) DESC NULLS LAST) = 1
),
event_level AS (         -- pull event-level details for that category
    SELECT
        MAX( CASE WHEN ep.value:"key"::STRING = 'transaction_id'
                  THEN ep.value:"value":"string_value"::STRING END )            AS transaction_id,
        SUM( i.value:"quantity"::NUMBER )                                       AS total_item_qty,
        MAX( CASE WHEN ep.value:"key"::STRING = 'value'
                  THEN ep.value:"value":"double_value"::FLOAT END )             AS purchase_revenue_usd,
        SUM( i.value:"item_revenue"::FLOAT )                                    AS purchase_revenue
    FROM   GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201130"  e
           , top_category tc
           , LATERAL FLATTEN( input => e."ITEMS")                 i
           , LATERAL FLATTEN( input => e."EVENT_PARAMS")          ep
    WHERE  e."EVENT_NAME" = 'purchase'
      AND  i.value:"item_category"::STRING = tc.item_category
    GROUP  BY e."EVENT_TIMESTAMP"
)
SELECT
       transaction_id,
       total_item_qty,
       purchase_revenue_usd,
       purchase_revenue
FROM   event_level
ORDER  BY transaction_id;
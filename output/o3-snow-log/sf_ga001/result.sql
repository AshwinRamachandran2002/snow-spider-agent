WITH december_purchases AS (

    /* ----------------------------------------------------
       1.  Collect every purchase event from December 2020
           and explode the ITEMS array into one row per item
       ---------------------------------------------------- */
    SELECT
        p."EVENT_DATE",
        p."EVENT_TIMESTAMP",
        p."USER_PSEUDO_ID",
        itm.value:"item_name"::string   AS item_name,
        itm.value:"item_id"::string     AS item_id,
        COALESCE(itm.value:"quantity"::NUMBER,1) AS quantity
    FROM (

        /* ----  All December 2020 event tables, UNION-ed ---- */
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230"
        UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"

    )          p
    , LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(p."ITEMS")) itm
    WHERE p."EVENT_NAME" = 'purchase'

), target_purchase_events AS (

    /* ----------------------------------------------------
       2.  Identify the purchase events that contained the
           Google Navy Speckled Tee
       ---------------------------------------------------- */
    SELECT DISTINCT
           "USER_PSEUDO_ID",
           "EVENT_TIMESTAMP"
    FROM   december_purchases
    WHERE  item_name = 'Google Navy Speckled Tee'

), companion_items AS (

    /* ----------------------------------------------------
       3.  Fetch every OTHER item that occurred in those
           same purchase events and sum the quantities
       ---------------------------------------------------- */
    SELECT
        dp.item_name               AS other_product,
        SUM(dp.quantity)           AS total_quantity
    FROM   december_purchases   dp
    JOIN   target_purchase_events tpe
           ON  dp."USER_PSEUDO_ID" = tpe."USER_PSEUDO_ID"
           AND dp."EVENT_TIMESTAMP" = tpe."EVENT_TIMESTAMP"
    WHERE  dp.item_name <> 'Google Navy Speckled Tee'
    GROUP  BY dp.item_name

)

-- --------------------------------------------------------
-- 4.  Return the product with the highest total quantity
-- --------------------------------------------------------
SELECT
    other_product,
    total_quantity
FROM   companion_items
ORDER  BY total_quantity DESC NULLS LAST
LIMIT  1;
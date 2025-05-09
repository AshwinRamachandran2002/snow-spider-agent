/* ------------------------------------------------------------
   PLP-to-PDP transition ratio for 2-Jan-2021 (page_view only)
-------------------------------------------------------------*/
WITH page_views AS (     -- step-1 : pull the needed fields
    SELECT
        t."USER_PSEUDO_ID",
        t."EVENT_TIMESTAMP",
        ep_sess.value:"int_value"::NUMBER   AS "ga_session_id",
        ep_loc.value:"string_value"::STRING AS "page_location"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ep_loc,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ep_sess
    WHERE t."EVENT_NAME" = 'page_view'
      AND ep_loc.value:"key"::STRING  = 'page_location'
      AND ep_sess.value:"key"::STRING = 'ga_session_id'
),

/* ------------------------------------------------------------
   step-2 : classify PLP views
-------------------------------------------------------------*/
plp AS (
    SELECT *
    FROM page_views
    WHERE
          ARRAY_SIZE(SPLIT("page_location", '/')) >= 5             -- ≥5 segments
      AND POSITION('+', SPLIT_PART("page_location", '/', 4)) = 0   -- no “+” in 4th
      AND POSITION('+', SPLIT_PART("page_location", '/', 5)) = 0   -- no “+” in 5th
      AND (                                                         -- category test on 4th / 5th
           SPLIT_PART("page_location", '/', 4) ILIKE ANY
           (
            '%Accessories%','%Apparel%','%Brands%','%Campus Collection%','%Drinkware%',
            '%Electronics%','%Google Redesign%','%Lifestyle%','%Nest%','%New 2015 Logo%',
            '%Notebooks Journals%','%Office%','%Shop by Brand%','%Small Goods%',
            '%Stationery%','%Wearables%'
           )
        OR SPLIT_PART("page_location", '/', 5) ILIKE ANY
           (
            '%Accessories%','%Apparel%','%Brands%','%Campus Collection%','%Drinkware%',
            '%Electronics%','%Google Redesign%','%Lifestyle%','%Nest%','%New 2015 Logo%',
            '%Notebooks Journals%','%Office%','%Shop by Brand%','%Small Goods%',
            '%Stationery%','%Wearables%'
           )
      )
),

/* ------------------------------------------------------------
   step-3 : classify PDP views
-------------------------------------------------------------*/
pdp AS (
    SELECT *
    FROM page_views
    WHERE
          ARRAY_SIZE(SPLIT("page_location", '/')) >= 5
      AND POSITION('+', SPLIT_PART("page_location", '/', -1)) > 0  -- “+” in last segment
      AND (                                                         -- same category test
           SPLIT_PART("page_location", '/', 4) ILIKE ANY
           (
            '%Accessories%','%Apparel%','%Brands%','%Campus Collection%','%Drinkware%',
            '%Electronics%','%Google Redesign%','%Lifestyle%','%Nest%','%New 2015 Logo%',
            '%Notebooks Journals%','%Office%','%Shop by Brand%','%Small Goods%',
            '%Stationery%','%Wearables%'
           )
        OR SPLIT_PART("page_location", '/', 5) ILIKE ANY
           (
            '%Accessories%','%Apparel%','%Brands%','%Campus Collection%','%Drinkware%',
            '%Electronics%','%Google Redesign%','%Lifestyle%','%Nest%','%New 2015 Logo%',
            '%Notebooks Journals%','%Office%','%Shop by Brand%','%Small Goods%',
            '%Stationery%','%Wearables%'
           )
      )
),

/* ------------------------------------------------------------
   step-4 : PLP views that have a later PDP in the SAME session
-------------------------------------------------------------*/
plp_with_pdp AS (
    SELECT DISTINCT
           plp."USER_PSEUDO_ID",
           plp."EVENT_TIMESTAMP"
    FROM plp
    JOIN pdp
      ON plp."USER_PSEUDO_ID" = pdp."USER_PSEUDO_ID"
     AND plp."ga_session_id"  = pdp."ga_session_id"
     AND plp."EVENT_TIMESTAMP" < pdp."EVENT_TIMESTAMP"
),

/* ------------------------------------------------------------
   step-5 : final numbers & percentage
-------------------------------------------------------------*/
summary AS (
    SELECT
        COUNT(*)                                        AS "plp_that_led_to_pdp",
        (SELECT COUNT(*) FROM plp)                      AS "total_plp",
        ROUND(
              COUNT(*) * 100.0
              / NULLIF( (SELECT COUNT(*) FROM plp), 0 )
             , 4)                                       AS "plp_to_pdp_percentage"
    FROM plp_with_pdp
)

SELECT *
FROM summary;
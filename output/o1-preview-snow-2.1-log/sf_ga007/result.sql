SELECT 
  ROUND((PDP_PAGE_VIEWS / TOTAL_PAGE_VIEWS::FLOAT) * 100, 4) AS "Percentage_PDP_PageViews"
FROM
  (
    SELECT COUNT(*) AS TOTAL_PAGE_VIEWS
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102"
    WHERE "EVENT_NAME" = 'page_view'
  ) AS TOTAL,
  (
    SELECT COUNT(*) AS PDP_PAGE_VIEWS
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
    LATERAL FLATTEN(input => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
      AND f.value:"key"::STRING = 'page_location'
      AND f.value:"value":"string_value"::STRING IS NOT NULL
      AND REGEXP_COUNT(f.value:"value":"string_value"::STRING, '/') >= 5
      AND SPLIT_PART(f.value:"value":"string_value"::STRING, '/', -1) LIKE '%+%'
      AND (
        SPLIT_PART(f.value:"value":"string_value"::STRING, '/', 5) ILIKE ANY (
          '%Accessories%', '%Apparel%', '%Brands%', '%Campus Collection%', '%Drinkware%', '%Electronics%',
          '%Google Redesign%', '%Lifestyle%', '%Nest%', '%New 2015 Logo%', '%Notebooks Journals%',
          '%Office%', '%Shop by Brand%', '%Small Goods%', '%Stationery%', '%Wearables%'
        )
        OR
        SPLIT_PART(f.value:"value":"string_value"::STRING, '/', 6) ILIKE ANY (
          '%Accessories%', '%Apparel%', '%Brands%', '%Campus Collection%', '%Drinkware%', '%Electronics%',
          '%Google Redesign%', '%Lifestyle%', '%Nest%', '%New 2015 Logo%', '%Notebooks Journals%',
          '%Office%', '%Shop by Brand%', '%Small Goods%', '%Stationery%', '%Wearables%'
        )
      )
  ) AS PDP;
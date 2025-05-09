WITH categories AS (
  SELECT 'Accessories' AS category_name UNION ALL
  SELECT 'Apparel' UNION ALL
  SELECT 'Brands' UNION ALL
  SELECT 'Campus+Collection' UNION ALL
  SELECT 'Drinkware' UNION ALL
  SELECT 'Electronics' UNION ALL
  SELECT 'Google+Redesign' UNION ALL
  SELECT 'Lifestyle' UNION ALL
  SELECT 'Nest' UNION ALL
  SELECT 'New+2015+Logo' UNION ALL
  SELECT 'Notebooks+Journals' UNION ALL
  SELECT 'Office' UNION ALL
  SELECT 'Shop+by+Brand' UNION ALL
  SELECT 'Small+Goods' UNION ALL
  SELECT 'Stationery' UNION ALL
  SELECT 'Wearables'
),
page_views AS (
  SELECT
    t."USER_PSEUDO_ID",
    t."EVENT_TIMESTAMP",
    ep_gasession.value:"value":"int_value"::NUMBER AS "ga_session_id",
    ep.value:"value":"string_value"::STRING AS "page_location"
  FROM
    "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t
    , LATERAL FLATTEN(input => t."EVENT_PARAMS") ep
    , LATERAL FLATTEN(input => t."EVENT_PARAMS") ep_gasession
  WHERE
    t."EVENT_NAME" = 'page_view'
    AND ep.value:"key"::STRING = 'page_location'
    AND ep_gasession.value:"key"::STRING = 'ga_session_id'
),
classified_pages AS (
  SELECT
    pv.*,
    ARRAY_SIZE( SPLIT( pv."page_location", '/') ) AS segments_count,
    SPLIT( pv."page_location", '/') [4] AS segment4,
    SPLIT( pv."page_location", '/') [5] AS segment5
  FROM
    page_views pv
),
classified_pages2 AS (
  SELECT
    cp.*,
    CASE WHEN
      cp.segments_count >= 6
      AND POSITION('+' IN cp.segment4) = 0
      AND POSITION('+' IN cp.segment5) = 0
      AND (
        cp.segment4 IN (SELECT category_name FROM categories)
        OR cp.segment5 IN (SELECT category_name FROM categories)
      )
    THEN 1 ELSE 0 END AS Is_PLP,
    CASE WHEN
      cp.segments_count >=6
      AND POSITION('+' IN cp.segment5) > 0
      AND (
        cp.segment4 IN (SELECT category_name FROM categories)
        OR cp.segment5 IN (SELECT category_name FROM categories)
      )
    THEN 1 ELSE 0 END AS Is_PDP
  FROM
    classified_pages cp
),
sessions_with_plp_pdp AS (
  SELECT
    cp2."ga_session_id",
    MAX(cp2.Is_PLP) AS has_plp,
    MAX(cp2.Is_PDP) AS has_pdp
  FROM
    classified_pages2 cp2
  GROUP BY
    cp2."ga_session_id"
)
SELECT
  ROUND( (COUNT(CASE WHEN has_plp =1 AND has_pdp=1 THEN 1 END) * 100.0 ) / NULLIF (COUNT(*),0), 4 ) AS Percentage_from_PLP_to_PDP
FROM
  sessions_with_plp_pdp;
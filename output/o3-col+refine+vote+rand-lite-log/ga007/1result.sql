-- Percentage of 2-Jan-2021 page views that are Product-Detail-Pages (PDPs)
WITH page_views AS (      -- pull every page_view URL for 2021-01-02
  SELECT ep.value.string_value AS url
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS e
  CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE e.event_name = 'page_view'
    AND ep.key       = 'page_location'
),
parts AS (                -- split the URL path into segments
  SELECT
    url,
    SPLIT(REGEXP_EXTRACT(url, r'^https?://[^/]+/(.*)$'), '/') AS seg
  FROM page_views
),
flag AS (                 -- mark each URL as PDP (1) or not (0)
  SELECT
    CASE
      WHEN ARRAY_LENGTH(seg) >= 5                                   -- ≥5 segments
       AND REGEXP_CONTAINS(seg[ORDINAL(ARRAY_LENGTH(seg))], r'\+')  -- “+” in last segment
       AND (                                                        -- category keyword in 4th or 5th segment
            REGEXP_CONTAINS(LOWER(seg[SAFE_ORDINAL(4)]),
              r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
         OR REGEXP_CONTAINS(LOWER(seg[SAFE_ORDINAL(5)]),
              r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
           )
      THEN 1
      ELSE 0
    END AS is_pdp
  FROM parts
)
SELECT
  COUNTIF(is_pdp = 1)                      AS pdp_views,
  COUNT(*)                                 AS total_page_views,
  ROUND(100 * SAFE_DIVIDE(SUM(is_pdp),     -- percentage
                          COUNT(*)), 4)    AS pdp_percentage
FROM flag;
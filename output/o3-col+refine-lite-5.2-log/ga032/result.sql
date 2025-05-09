WITH page_views AS (
  SELECT
    event_timestamp,
    (SELECT value.string_value
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'page_title')     AS page_title,
    (SELECT value.string_value
       FROM UNNEST(event_params) AS p
       WHERE p.key = 'page_location')  AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_name     = 'page_view'
),
classified AS (
  SELECT
    event_timestamp,
    CASE
      WHEN page_location IS NULL THEN page_title
      /* PDP : five‑segment URL, “+” in last segment, and category keyword present */
      WHEN REGEXP_CONTAINS(page_location,
             r'(?i)^https?://[^/]+/[^/]+/[^/]+/[^/]+/.+\+.+' )
           AND REGEXP_CONTAINS(page_location,
             r'(?i)Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables')
           THEN 'PDP'
      /* PLP : five‑segment URL, no “+” in last segment, and category keyword present */
      WHEN REGEXP_CONTAINS(page_location,
             r'(?i)^https?://[^/]+/[^/]+/[^/]+/[^/]+/[^/]+$')
           AND NOT REGEXP_CONTAINS(REGEXP_EXTRACT(page_location, r'[^/]+$'), r'\+')
           AND REGEXP_CONTAINS(page_location,
             r'(?i)Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables')
           THEN 'PLP'
      /* fallback to the raw page title */
      ELSE page_title
    END AS node
  FROM page_views
),
dedup AS (   -- remove adjacent duplicates
  SELECT
    event_timestamp,
    node,
    LAG(node) OVER (ORDER BY event_timestamp) AS prev_node
  FROM classified
),
filtered AS (
  SELECT event_timestamp, node
  FROM dedup
  WHERE node IS DISTINCT FROM prev_node
  ORDER BY event_timestamp
)
SELECT STRING_AGG(node, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM   filtered;
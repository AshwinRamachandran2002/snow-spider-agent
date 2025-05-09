WITH page_views AS (
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'page_location') AS page_location,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'page_title')     AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE event_date    = '20210128'
    AND user_pseudo_id = '1362228.4966015575'
    AND event_name    = 'page_view'
),
classified AS (
  SELECT
    event_timestamp,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(page_location),
           r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)(/|$)')
           AND REGEXP_CONTAINS(page_location, r'\+[^/]*$')
        THEN 'PDP'
      WHEN REGEXP_CONTAINS(LOWER(page_location),
           r'/(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)(/|$)')
           AND NOT REGEXP_CONTAINS(page_location, r'\+[^/]*$')
        THEN 'PLP'
      ELSE COALESCE(page_title, 'OTHER')
    END AS node
  FROM page_views
),
dedup AS (
  SELECT
    node,
    event_timestamp,
    LAG(node) OVER (ORDER BY event_timestamp) AS prev_node
  FROM classified
)
SELECT STRING_AGG(node, ' >> ' ORDER BY event_timestamp) AS navigation_flow
FROM dedup
WHERE prev_node IS NULL OR node != prev_node;
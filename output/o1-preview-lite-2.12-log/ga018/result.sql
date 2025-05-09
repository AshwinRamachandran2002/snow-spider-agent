WITH categories AS (
  SELECT LOWER(REPLACE('Accessories', ' ', '+')) AS category UNION ALL
  SELECT LOWER(REPLACE('Apparel', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Brands', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Campus Collection', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Drinkware', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Electronics', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Google Redesign', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Lifestyle', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Nest', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('New 2015 Logo', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Notebooks Journals', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Office', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Shop by Brand', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Small Goods', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Stationery', ' ', '+')) UNION ALL
  SELECT LOWER(REPLACE('Wearables', ' ', '+'))
),
page_views AS (
  SELECT
    t.user_pseudo_id,
    t.event_timestamp,
    LOWER(ep.value.string_value) AS page_location,
    REGEXP_REPLACE(LOWER(ep.value.string_value), r'^https?://[^/]+/?', '') AS path,
    SPLIT(REGEXP_REPLACE(LOWER(ep.value.string_value), r'^https?://[^/]+/?', ''), '/') AS path_segments
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  JOIN UNNEST(t.event_params) AS ep
    ON ep.key = 'page_location'
  WHERE
    t.event_name = 'page_view'
    AND ep.value.string_value IS NOT NULL
),
sessionized_events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    page_location,
    path_segments,
    IF(
      event_timestamp - LAG(event_timestamp) OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) > 1800000000 OR
      LAG(event_timestamp) OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) IS NULL,
      1,
      0
    ) AS new_session_indicator
  FROM page_views
),
sessions AS (
  SELECT
    *,
    SUM(new_session_indicator) OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) AS session_id
  FROM sessionized_events
),
plp_views AS (
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp
  FROM sessions
  WHERE
    ARRAY_LENGTH(path_segments) >= 2
    AND NOT CONTAINS_SUBSTR(path_segments[SAFE_OFFSET(ARRAY_LENGTH(path_segments)-1)], '+')
    AND (
      path_segments[SAFE_OFFSET(0)] IN (SELECT category FROM categories)
      OR path_segments[SAFE_OFFSET(1)] IN (SELECT category FROM categories)
    )
),
pdp_views AS (
  SELECT
    user_pseudo_id,
    session_id,
    event_timestamp
  FROM sessions
  WHERE
    ARRAY_LENGTH(path_segments) >= 2
    AND CONTAINS_SUBSTR(path_segments[SAFE_OFFSET(ARRAY_LENGTH(path_segments)-1)], '+')
    AND (
      path_segments[SAFE_OFFSET(0)] IN (SELECT category FROM categories)
      OR path_segments[SAFE_OFFSET(1)] IN (SELECT category FROM categories)
    )
),
plp_to_pdp AS (
  SELECT DISTINCT
    plp.user_pseudo_id,
    plp.session_id,
    plp.event_timestamp AS plp_timestamp
  FROM plp_views AS plp
  JOIN pdp_views AS pdp
    ON plp.user_pseudo_id = pdp.user_pseudo_id
    AND plp.session_id = pdp.session_id
    AND pdp.event_timestamp > plp.event_timestamp
)
SELECT
  (SELECT COUNT(*) FROM plp_to_pdp) AS Number_of_PLP_views_leading_to_PDP_views,
  (SELECT COUNT(*) FROM plp_views) AS Total_PLP_views,
  ROUND(
    (SELECT COUNT(*) FROM plp_to_pdp) / NULLIF((SELECT COUNT(*) FROM plp_views), 0) * 100,
    4
  ) AS Percentage_of_PLP_to_PDP_transitions;
WITH page_views AS (
  SELECT
    t.user_pseudo_id,
    t.event_timestamp,
    ep.value.string_value AS page_location
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` t,
  UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
),
parsed_page_views AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    page_location,
    SPLIT(page_location, '/') AS segments,
    ARRAY_LENGTH(SPLIT(page_location, '/')) AS num_segments
  FROM page_views
),
categorized_views AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    page_location,
    LOWER(REPLACE(segments[SAFE_OFFSET(3)], '+', ' ')) AS segment_4,
    LOWER(REPLACE(segments[SAFE_OFFSET(4)], '+', ' ')) AS segment_5,
    LOWER(REPLACE(segments[SAFE_OFFSET(num_segments - 1)], '+', ' ')) AS last_segment,
    num_segments
  FROM parsed_page_views
),
classified_views AS (
  SELECT
    *,
    CASE
      WHEN num_segments >= 5
        AND (
          segment_4 IN ('accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables')
          OR segment_5 IN ('accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables')
        )
        AND last_segment IN ('accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables')
      THEN TRUE
      ELSE FALSE
    END AS is_plp,
    CASE
      WHEN num_segments >= 5
        AND (
          segment_4 IN ('accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables')
          OR segment_5 IN ('accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables')
        )
        AND last_segment NOT IN ('accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables')
      THEN TRUE
      ELSE FALSE
    END AS is_pdp
  FROM categorized_views
),
transitions AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    is_plp,
    LEAD(is_pdp) OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) AS next_is_pdp
  FROM classified_views
)
SELECT
  COUNTIF(is_plp AND next_is_pdp) AS Number_of_PLP_views_leading_to_PDP_views,
  COUNTIF(is_plp) AS Total_PLP_views,
  ROUND((COUNTIF(is_plp AND next_is_pdp) / NULLIF(COUNTIF(is_plp), 0)) * 100, 4) AS Percentage_of_PLP_to_PDP_transitions
FROM transitions;
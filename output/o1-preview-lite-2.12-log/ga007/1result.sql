SELECT
  ROUND(100 * SUM(CASE WHEN is_pdp THEN 1 ELSE 0 END) / COUNT(*), 4) AS Percentage_of_PDP_Page_Views
FROM (
  SELECT
    (
      ARRAY_LENGTH(segments) >= 5
      AND CONTAINS_SUBSTR(segments[OFFSET(ARRAY_LENGTH(segments) - 1)], '+')
      AND (
        LOWER(segments[OFFSET(3)]) IN (
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods', 'stationery', 'wearables'
        )
        OR LOWER(segments[OFFSET(4)]) IN (
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods', 'stationery', 'wearables'
        )
      )
    ) AS is_pdp
  FROM (
    SELECT
      SPLIT(ep.value.string_value, '/') AS segments
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t,
    UNNEST(t.event_params) AS ep
    WHERE t.event_name = 'page_view' AND ep.key = 'page_location'
  )
)
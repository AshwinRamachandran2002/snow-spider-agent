SELECT
  ROUND((SAFE_DIVIDE(pdp.pdp_page_views, total.total_page_views)) * 100, 4) AS Percentage_of_PDP_Page_Views
FROM (
  SELECT COUNT(*) AS total_page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
) AS total,
(
  SELECT COUNT(DISTINCT t.event_timestamp) AS pdp_page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t,
  UNNEST(t.event_params) AS ep
  WHERE t.event_name = 'page_view'
    AND ep.key = 'page_location'
    AND ARRAY_LENGTH(SPLIT(ep.value.string_value, '/')) >= 5
    AND REGEXP_CONTAINS(
      SPLIT(ep.value.string_value, '/')[ORDINAL(ARRAY_LENGTH(SPLIT(ep.value.string_value, '/')))],
      r'\+'
    )
    AND (
      LOWER(SPLIT(ep.value.string_value, '/')[OFFSET(3)]) IN UNNEST([
        'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
        'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
        'notebooks+journals', 'office', 'shop+by+brand', 'small+goods',
        'stationery', 'wearables'
      ])
      OR
      LOWER(SPLIT(ep.value.string_value, '/')[OFFSET(4)]) IN UNNEST([
        'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
        'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
        'notebooks+journals', 'office', 'shop+by+brand', 'small+goods',
        'stationery', 'wearables'
      ])
    )
) AS pdp;
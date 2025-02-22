-- Task: Calculate the percentage of 'page_view' events on January 2, 2021, that are Product Detail Page (PDP) views. A PDP view is defined as a 'page_view' event where the 'page_location' parameter meets the following criteria:
-- 1. The URL path has at least 5 segments when split by '/'.
-- 2. The last segment of the URL contains a '+' character.
-- 3. Either the 4th or 5th segment of the URL path (when converted to lowercase) matches one of the following categories:
--    'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
--    'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
--    'notebooks+journals', 'office', 'shop+by+brand', 'small+goods',
--    'stationery', 'wearables'.
SELECT
  ROUND(SAFE_DIVIDE(pdp.pdp_page_views, total.total_page_views) * 100, 4) AS Percentage_of_PDP_Page_Views
FROM
  (
    SELECT
      COUNT(*) AS total_page_views
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
    WHERE
      event_name = 'page_view'
  ) AS total,
  (
    SELECT
      COUNT(*) AS pdp_page_views
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
      INNER JOIN UNNEST(t.event_params) AS ep
        ON ep.key = 'page_location'
    WHERE
      t.event_name = 'page_view'
      AND ARRAY_LENGTH(SPLIT(ep.value.string_value, '/')) >= 5
      AND REGEXP_CONTAINS(
        SPLIT(ep.value.string_value, '/')[OFFSET(ARRAY_LENGTH(SPLIT(ep.value.string_value, '/')) - 1)],
        r'\+'
      )
      AND (
        LOWER(SPLIT(ep.value.string_value, '/')[SAFE_OFFSET(3)]) IN (
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods',
          'stationery', 'wearables'
        )
        OR
        LOWER(SPLIT(ep.value.string_value, '/')[SAFE_OFFSET(4)]) IN (
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods',
          'stationery', 'wearables'
        )
      )
  ) AS pdp;
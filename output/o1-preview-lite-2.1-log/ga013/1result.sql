SELECT DISTINCT
  (SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_title' LIMIT 1) AS Page_Name,
  CASE
    WHEN
      ARRAY_LENGTH(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')) >= 5
      AND REGEXP_CONTAINS(
        SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(ARRAY_LENGTH(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')) - 1)],
        r'\+'
      )
      AND (
        LOWER(REPLACE(IFNULL(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(3)], ''), '+', ' ')) IN (
          'accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables'
        )
        OR LOWER(REPLACE(IFNULL(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(4)], ''), '+', ' ')) IN (
          'accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables'
        )
      )
    THEN 'PDP'
    WHEN
      ARRAY_LENGTH(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')) >= 5
      AND NOT REGEXP_CONTAINS(
        IFNULL(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(3)], ''),
        r'\+'
      )
      AND NOT REGEXP_CONTAINS(
        IFNULL(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(4)], ''),
        r'\+'
      )
      AND (
        LOWER(REPLACE(IFNULL(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(3)], ''), '+', ' ')) IN (
          'accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables'
        )
        OR LOWER(REPLACE(IFNULL(SPLIT(REGEXP_REPLACE((SELECT ep.value.string_value FROM UNNEST(event_params) AS ep WHERE ep.key = 'page_location' LIMIT 1), r'^https?://[^/]+', ''), '/')[OFFSET(4)], ''), '+', ' ')) IN (
          'accessories', 'apparel', 'brands', 'campus collection', 'drinkware', 'electronics', 'google redesign', 'lifestyle', 'nest', 'new 2015 logo', 'notebooks journals', 'office', 'shop by brand', 'small goods', 'stationery', 'wearables'
        )
      )
    THEN 'PLP'
    ELSE 'Other'
  END AS Page_Type
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
WHERE
  user_pseudo_id = '1402138.5184246691' AND event_name = 'page_view';
SELECT
  Page_Name,
  CASE
    WHEN
      num_segments >= 5
      AND (
        REGEXP_CONTAINS(segment4, r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
        OR
        REGEXP_CONTAINS(segment5, r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
      )
      AND REGEXP_CONTAINS(last_segment, r'\+')
    THEN 'PDP'
    WHEN
      num_segments >= 5
      AND (
        REGEXP_CONTAINS(segment4, r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
        OR
        REGEXP_CONTAINS(segment5, r'(?i)(Accessories|Apparel|Brands|Campus\+Collection|Drinkware|Electronics|Google\+Redesign|Lifestyle|Nest|New\+2015\+Logo|Notebooks\+Journals|Office|Shop\+by\+Brand|Small\+Goods|Stationery|Wearables)')
      )
      AND NOT REGEXP_CONTAINS(segment4, r'\+')
      AND NOT REGEXP_CONTAINS(segment5, r'\+')
    THEN 'PLP'
    ELSE 'Other'
  END AS Page_Type
FROM (
  SELECT
    Page_Name,
    SPLIT(path, '/') AS path_segments,
    ARRAY_LENGTH(SPLIT(path, '/')) AS num_segments,
    SPLIT(path, '/')[SAFE_ORDINAL(4)] AS segment4,
    SPLIT(path, '/')[SAFE_ORDINAL(5)] AS segment5,
    SPLIT(path, '/')[ORDINAL(ARRAY_LENGTH(SPLIT(path, '/')))] AS last_segment
  FROM (
    SELECT
      ep_page_location.value.string_value AS Page_Name,
      REGEXP_EXTRACT(ep_page_location.value.string_value, r'https?://[^/]+(/.*)') AS path
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS e
    CROSS JOIN UNNEST(e.event_params) AS ep_page_location
    WHERE e.user_pseudo_id = '1402138.5184246691'
      AND ep_page_location.key = 'page_location'
      AND ep_page_location.value.string_value IS NOT NULL
  )
)
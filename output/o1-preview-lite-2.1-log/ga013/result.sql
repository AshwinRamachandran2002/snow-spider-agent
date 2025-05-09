SELECT DISTINCT
  page_title AS Page_Name,
  CASE
    WHEN 
      ARRAY_LENGTH(url_segments) >= 5 AND
      (
        LOWER(url_segments[SAFE_OFFSET(3)]) IN UNNEST([
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods', 'stationery',
          'wearables'
        ])
        OR
        LOWER(url_segments[SAFE_OFFSET(4)]) IN UNNEST([
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods', 'stationery',
          'wearables'
        ])
      )
      AND
      (NOT REGEXP_CONTAINS(url_segments[SAFE_OFFSET(4)], r'\+') AND NOT REGEXP_CONTAINS(url_segments[SAFE_OFFSET(5)], r'\+'))
    THEN 'PLP'
    WHEN 
      ARRAY_LENGTH(url_segments) >= 5 AND
      (
        LOWER(url_segments[SAFE_OFFSET(3)]) IN UNNEST([
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods', 'stationery',
          'wearables'
        ])
        OR
        LOWER(url_segments[SAFE_OFFSET(4)]) IN UNNEST([
          'accessories', 'apparel', 'brands', 'campus+collection', 'drinkware',
          'electronics', 'google+redesign', 'lifestyle', 'nest', 'new+2015+logo',
          'notebooks+journals', 'office', 'shop+by+brand', 'small+goods', 'stationery',
          'wearables'
        ])
      )
      AND
      (REGEXP_CONTAINS(url_segments[SAFE_OFFSET(4)], r'\+') OR REGEXP_CONTAINS(url_segments[SAFE_OFFSET(5)], r'\+'))
    THEN 'PDP'
    ELSE 'Other'
  END AS Page_Type
FROM (
  SELECT
    page_title,
    SPLIT(REGEXP_EXTRACT(page_location, r'https?://[^/]+(/.*)'), '/') AS url_segments
  FROM (
    SELECT
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
    WHERE
      user_pseudo_id = '1402138.5184246691'
  )
  WHERE
    page_location IS NOT NULL
)
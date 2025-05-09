-- Pages viewed by user 1402138.5184246691 on 02-Jan-2021
WITH hits AS (
  SELECT
    MAX(CASE WHEN ep.key = 'page_title'    THEN ep.value.string_value END) AS page_title,
    MAX(CASE WHEN ep.key = 'page_location' THEN ep.value.string_value END) AS page_location
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`,
    UNNEST(event_params) AS ep
  WHERE
    user_pseudo_id = '1402138.5184246691'
  GROUP BY
    event_timestamp
)

SELECT DISTINCT
  page_title,
  CASE
    -- Product Detail Page
    WHEN REGEXP_CONTAINS(LOWER(page_location), r'/[^/]*\+[^/]*$')
         AND REGEXP_CONTAINS(LOWER(page_location),
             r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
         THEN 'PDP'
    -- Product Listing Page
    WHEN REGEXP_CONTAINS(LOWER(page_location),
             r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
         AND NOT REGEXP_CONTAINS(LOWER(page_location), r'/[^/]*\+[^/]*$')
         THEN 'PLP'
    -- Anything else
    ELSE 'Other'
  END AS page_type
FROM
  hits
ORDER BY
  page_title;
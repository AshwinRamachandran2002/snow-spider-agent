-- pages visited by the requested user on 2 Jan 2021  
WITH user_pageviews AS (        -- pull only page‑view events for that user & day
  SELECT
    (SELECT value.string_value
       FROM UNNEST(event_params)
      WHERE key = 'page_title'
      LIMIT 1)                                       AS page_title ,
    (SELECT value.string_value
       FROM UNNEST(event_params)
      WHERE key = 'page_location'
      LIMIT 1)                                       AS page_location
  FROM   `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE  event_name    = 'page_view'
    AND  event_date    = '20210102'
    AND  user_pseudo_id = '1402138.5184246691'
),

classified AS (
  SELECT
    page_title ,
    page_location ,

    /* -------- page‑type classification ------------- */
    CASE
      WHEN page_location IS NOT NULL
           AND REGEXP_CONTAINS(LOWER(page_location),
               r'/((accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables))/')
           AND ARRAY_LENGTH(SPLIT(
                 REGEXP_EXTRACT(page_location, r'https?://[^/]+/(.*)') , '/')) >= 5
           AND REGEXP_CONTAINS(page_location , r'/[^/]*\+[^/]*$')
        THEN 'PDP'                                          -- product‑detail page

      WHEN page_location IS NOT NULL
           AND REGEXP_CONTAINS(LOWER(page_location),
               r'/((accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables))/')
           AND ARRAY_LENGTH(SPLIT(
                 REGEXP_EXTRACT(page_location, r'https?://[^/]+/(.*)') , '/')) >= 5
           AND NOT REGEXP_CONTAINS(page_location , r'/[^/]*\+[^/]*$')
        THEN 'PLP'                                          -- product‑listing page

      ELSE page_title                                       -- leave original name
    END                                             AS page_name
  FROM user_pageviews
)

SELECT DISTINCT
       page_name                -- final list of visited pages (with PDP/PLP where applicable)
FROM   classified
WHERE  page_name IS NOT NULL
ORDER  BY page_name;
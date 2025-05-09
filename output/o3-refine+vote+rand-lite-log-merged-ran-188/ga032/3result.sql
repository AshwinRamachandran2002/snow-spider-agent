/* Navigation flow (with PDP / PLP tagging and de-duplication) 
   for user 1362228.4966015575 on 28-Jan-2021                         */

WITH pageviews AS (                       -- pull raw page_view hits
  SELECT
    event_timestamp,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_title'
      LIMIT 1)                                                  AS page_title,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'page_location'
      LIMIT 1)                                                  AS page_location,
    SPLIT(                                                     -- pre-split URL
      REGEXP_REPLACE(
        (SELECT ep.value.string_value
           FROM UNNEST(event_params) ep
          WHERE ep.key = 'page_location'
          LIMIT 1),
        r'^https?://', ''
      ),
      '/'
    )                                                           AS segments
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  WHERE user_pseudo_id = '1362228.4966015575'
    AND event_date     = '20210128'
    AND event_name     = 'page_view'
),

typed_pages AS (                       -- classify every page
  SELECT
    event_timestamp,
    page_title,
    CASE
      WHEN page_location IS NULL THEN 'Other'
      WHEN ARRAY_LENGTH(segments) >= 5
           AND ( REGEXP_CONTAINS(
                   LOWER(segments[ORDINAL(4)]),
                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)')
              OR REGEXP_CONTAINS(
                   LOWER(segments[ORDINAL(5)]),
                   r'(accessories|apparel|brands|campus\+collection|drinkware|electronics|google\+redesign|lifestyle|nest|new\+2015\+logo|notebooks\+journals|office|shop\+by\+brand|small\+goods|stationery|wearables)') )
        THEN IF( REGEXP_CONTAINS(
                   segments[OFFSET(ARRAY_LENGTH(segments) - 1)],
                   r'\+'),
                  'PDP',
                  'PLP')
      ELSE 'Other'
    END                                                         AS page_type
  FROM pageviews
),

collapsed AS (                         -- drop consecutive duplicates
  SELECT *
  FROM (
    SELECT
      *,
      LAG(page_title) OVER(ORDER BY event_timestamp) AS prev_title
    FROM typed_pages
  )
  WHERE prev_title IS NULL OR prev_title != page_title
)

SELECT
  STRING_AGG(
    CASE WHEN page_type IN ('PDP','PLP')
         THEN page_type
         ELSE page_title
    END,
    ' >> '
    ORDER BY event_timestamp
  ) AS navigation_flow
FROM collapsed;
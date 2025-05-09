SELECT
  ROUND((COUNTIF('Checkout Confirmation' IN UNNEST(page_titles)) / COUNT(*)) * 100, 4) AS User_Session_Conversion_Rate
FROM (
  SELECT
    ga_session_id,
    ARRAY_AGG(DISTINCT page_title) AS page_titles
  FROM (
    SELECT
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
    WHERE event_name = 'page_view' AND event_date = '20210102'
  )
  GROUP BY ga_session_id
  HAVING 'Home' IN UNNEST(page_titles)
)
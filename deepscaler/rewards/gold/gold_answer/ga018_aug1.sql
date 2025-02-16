-- Task: On January 2nd, 2021, could you list the first 100 'page_view' events with their 'page_title' and 'page_location'?

WITH base_table AS (
  SELECT
    event_name,
    event_date,
    event_timestamp,
    user_pseudo_id,
    event_params
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _table_suffix = '20210102'
    AND event_name = 'page_view'
)
SELECT
  date,
  event_timestamp_microseconds,
  user_pseudo_id,
  page_title,
  page_location
FROM (
  SELECT
    event_date AS date,
    event_timestamp AS event_timestamp_microseconds,
    user_pseudo_id,
    MAX(CASE WHEN c.key = 'page_title' THEN c.value.string_value END) AS page_title,
    MAX(CASE WHEN c.key = 'page_location' THEN c.value.string_value END) AS page_location
  FROM 
    base_table,
    UNNEST(event_params) c
  GROUP BY 1, 2, 3
)
LIMIT 100;
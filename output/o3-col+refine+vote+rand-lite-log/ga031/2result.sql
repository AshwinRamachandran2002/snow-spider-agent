WITH pageviews AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id')                      AS session_id,
    (SELECT ep.value.string_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'page_title')                         AS page_title
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  WHERE event_name = 'page_view'
),
session_flags AS (
  SELECT
    user_pseudo_id,
    session_id,
    MAX(LOWER(page_title) LIKE '%google online store%')                            AS has_home,
    MAX(LOWER(page_title) LIKE '%checkout%' OR LOWER(page_title) LIKE '%confirmation%') AS has_checkout
  FROM pageviews
  GROUP BY user_pseudo_id, session_id
)
SELECT
  SUM(CASE WHEN has_home THEN 1 END)                                                    AS sessions_with_home,
  SUM(CASE WHEN has_home AND has_checkout THEN 1 END)                                   AS sessions_converted,
  ROUND(
    100 * SUM(CASE WHEN has_home AND has_checkout THEN 1 END)
        / NULLIF(SUM(CASE WHEN has_home THEN 1 END), 0),
    2
  )                                                                                     AS conversion_rate_percent
FROM session_flags;
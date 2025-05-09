WITH plp_sessions AS (
  SELECT DISTINCT
    CONCAT(t.user_pseudo_id, '-', CAST((
      SELECT ep.value.int_value
      FROM UNNEST(t.event_params) AS ep
      WHERE ep.key = 'ga_session_id' LIMIT 1
    ) AS STRING)) AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  WHERE t.event_name = 'page_view'
    AND LOWER((
      SELECT ep.value.string_value
      FROM UNNEST(t.event_params) AS ep
      WHERE ep.key = 'page_location' LIMIT 1
    )) LIKE '%apparel%'
),
pdp_sessions AS (
  SELECT DISTINCT
    CONCAT(t.user_pseudo_id, '-', CAST((
      SELECT ep.value.int_value
      FROM UNNEST(t.event_params) AS ep
      WHERE ep.key = 'ga_session_id' LIMIT 1
    ) AS STRING)) AS session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
  WHERE t.event_name = 'view_item'
),
plp_pdp_sessions AS (
  SELECT session_id
  FROM plp_sessions
  INNER JOIN pdp_sessions USING (session_id)
)
SELECT
  100 * SAFE_DIVIDE(
    COUNT(DISTINCT session_id),
    (SELECT COUNT(DISTINCT session_id) FROM plp_sessions)
  ) AS Percentage
FROM
  plp_pdp_sessions
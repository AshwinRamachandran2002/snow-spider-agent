WITH home_sessions AS (
    SELECT DISTINCT session_id.value.int_value AS session_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t,
    UNNEST(t.event_params) AS page_title_param,
    UNNEST(t.event_params) AS session_id
    WHERE t.event_name = 'page_view'
      AND page_title_param.key = 'page_title'
      AND page_title_param.value.string_value = 'Home'
      AND session_id.key = 'ga_session_id'
),
checkout_sessions AS (
    SELECT DISTINCT session_id.value.int_value AS session_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t,
    UNNEST(t.event_params) AS page_title_param,
    UNNEST(t.event_params) AS session_id
    WHERE t.event_name = 'page_view'
      AND page_title_param.key = 'page_title'
      AND page_title_param.value.string_value = 'Checkout Confirmation'
      AND session_id.key = 'ga_session_id'
),
converted_sessions AS (
    SELECT hs.session_id
    FROM home_sessions hs
    INNER JOIN checkout_sessions cs
    ON hs.session_id = cs.session_id
)
SELECT ROUND((SELECT COUNT(*) FROM converted_sessions) * 100.0 / (SELECT COUNT(*) FROM home_sessions), 4) AS conversion_rate;
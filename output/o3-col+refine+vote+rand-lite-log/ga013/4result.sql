SELECT DISTINCT
  title.value.string_value AS page_name_or_title,
  CASE
    WHEN REGEXP_CONTAINS(loc.value.string_value, r'\+[^/]*$') THEN 'PDP'
    ELSE 'PLP'
  END AS adjusted_name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102` AS t
JOIN UNNEST(t.event_params) AS title ON title.key = 'page_title'
JOIN UNNEST(t.event_params) AS loc   ON loc.key  = 'page_location'
WHERE t.user_pseudo_id = '1402138.5184246691'
  AND t.event_name      = 'page_view';
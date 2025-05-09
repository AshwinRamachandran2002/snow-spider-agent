-- Total number of December-2020 sessions by traffic channel
WITH events_dec_2020 AS (
  SELECT
    user_pseudo_id,
    /* pull GA session-level parameters                           */
    (SELECT ep.value.int_value     FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id')  AS ga_session_id,
    LOWER( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source') ) AS source,
    LOWER( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium') ) AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),
sessions AS (
  /* one row per distinct session (user_pseudo_id + ga_session_id) */
  SELECT DISTINCT
    CONCAT(user_pseudo_id,'_',CAST(ga_session_id AS STRING)) AS session_key,
    source,
    medium
  FROM events_dec_2020
  WHERE ga_session_id IS NOT NULL               -- keep only valid sessions
)
SELECT
  /* simplified GA-style default channel grouping logic            */
  CASE
      WHEN source = '(direct)' AND (medium IS NULL OR medium IN ('(none)','(not set)'))
           THEN 'Direct'
      WHEN medium = 'referral'                                      THEN 'Referral'
      WHEN medium = 'organic'                                       THEN 'Organic Search'
      WHEN medium IN ('email','e-mail','e_mail','e mail')
           OR source IN ('email','e-mail','e_mail','e mail')        THEN 'Email'
      WHEN medium = 'affiliate'                                     THEN 'Affiliates'
      WHEN REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|paid.*)')
           AND source IN ('google','bing','baidu','yahoo',
                           'duckduckgo','ecosia','yandex')          THEN 'Paid Search'
      ELSE 'Unassigned'
  END AS channel,
  COUNT(*) AS total_sessions
FROM sessions
GROUP BY channel
ORDER BY total_sessions DESC;
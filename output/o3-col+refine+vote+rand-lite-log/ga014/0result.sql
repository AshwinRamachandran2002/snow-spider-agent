-- total number of December-2020 sessions by traffic channel
WITH session_events AS (          -- one row = one session (session_start event)
  SELECT
    IFNULL(
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'source')
    , '')                                         AS source,
    IFNULL(
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'medium')
    , '')                                         AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

labeled AS (                     -- map (source,medium) to GA4 default channel group
  SELECT
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)','(none)')                                                        THEN 'Direct'
      WHEN LOWER(medium) IN ('display','banner','expandable','interstitial','cpm')                                         THEN 'Display'
      WHEN LOWER(medium) = 'referral'                                                                                      THEN 'Referral'
      WHEN LOWER(medium) = 'email'
        OR LOWER(source) IN ('email','e-mail','e_mail','e mail')                                                           THEN 'Email'
      WHEN LOWER(medium) = 'affiliate'                                                                                     THEN 'Affiliates'
      WHEN LOWER(medium) = 'audio'                                                                                         THEN 'Audio'
      WHEN LOWER(medium) = 'sms'        OR LOWER(source) = 'sms'                                                           THEN 'SMS'
      WHEN REGEXP_CONTAINS(LOWER(medium), r'(.*push$|mobile|notification)')                                                THEN 'Mobile Push Notifications'
      WHEN LOWER(medium) = 'organic'                                                                                       THEN 'Organic Search'
      WHEN LOWER(medium) LIKE '%social%'                                                                                   THEN 'Organic Social'
      ELSE 'Unassigned'
    END AS channel_group
  FROM session_events
)

SELECT
  channel_group,
  COUNT(*) AS sessions
FROM labeled
GROUP BY channel_group
ORDER BY sessions DESC;
-- Total number of sessions for each traffic channel in December-2020
WITH dec_sessions AS (
  SELECT
    -- unique identifier per session
    CONCAT(
      user_pseudo_id, '-',
      CAST(
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id') AS STRING
      )
    ) AS session_key,

    -- acquisition dimensions (lower-cased, with fall-backs)
    LOWER(
      COALESCE(
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source'),
        '(direct)'
      )
    ) AS source,

    LOWER(
      COALESCE(
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium'),
        '(none)'
      )
    ) AS medium,

    LOWER(
      COALESCE(
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign'),
        ''
      )
    ) AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
)

SELECT
  CASE
    -- Direct
    WHEN source = '(direct)' AND medium IN ('(none)', '(not set)')                     THEN 'Direct'

    -- Cross-network
    WHEN REGEXP_CONTAINS(campaign, 'cross[-_ ]?network')                              THEN 'Cross-network'

    -- Paid groupings
    WHEN REGEXP_CONTAINS(medium, '(cpc|ppc|paid)') AND
         source IN ('google','bing','yahoo','baidu','duckduckgo','yandex','ecosia')    THEN 'Paid Search'
    WHEN REGEXP_CONTAINS(medium, '(cpc|ppc|paid|retargeting)') AND
         REGEXP_CONTAINS(source, '(amazon|etsy|ebay|stripe|alibaba|shopify|walmart)')  THEN 'Paid Shopping'
    WHEN REGEXP_CONTAINS(medium, '(cpc|ppc|paid|retargeting)') AND
         REGEXP_CONTAINS(source, '(facebook|instagram|linkedin|pinterest|tiktok|twitter|whatsapp|badoo|fb)')
                                                                                       THEN 'Paid Social'
    WHEN REGEXP_CONTAINS(medium, '(cpc|ppc|paid|retargeting)') AND
         REGEXP_CONTAINS(source, '(youtube|vimeo|twitch|dailymotion)')                 THEN 'Paid Video'

    -- Display
    WHEN medium IN ('display','banner','expandable','interstitial','cpm')             THEN 'Display'

    -- Organic groupings
    WHEN medium = 'organic' OR
         source IN ('google','bing','yahoo','duckduckgo','baidu','yandex','ecosia')    THEN 'Organic Search'
    WHEN REGEXP_CONTAINS(source, '(amazon|etsy|ebay|stripe|alibaba|shopify|walmart)')  THEN 'Organic Shopping'
    WHEN medium IN ('social','social-network','social-media','sm','social network','social media')
         OR REGEXP_CONTAINS(source, '(facebook|instagram|linkedin|pinterest|tiktok|twitter|whatsapp|badoo|fb)')
                                                                                       THEN 'Organic Social'
    WHEN REGEXP_CONTAINS(source, '(youtube|vimeo|twitch|dailymotion)')
         OR REGEXP_CONTAINS(medium, 'video')                                           THEN 'Organic Video'

    -- Referral
    WHEN medium = 'referral'                                                          THEN 'Referral'

    -- Email
    WHEN REGEXP_CONTAINS(medium, '(email|e-mail|e_mail|e mail)')
         OR REGEXP_CONTAINS(source, '(email|e-mail|e_mail|e mail)')                    THEN 'Email'

    -- Affiliates
    WHEN medium = 'affiliate'                                                         THEN 'Affiliates'

    -- Audio
    WHEN medium = 'audio'                                                             THEN 'Audio'

    -- SMS
    WHEN medium = 'sms' OR source = 'sms'                                             THEN 'SMS'

    -- Mobile Push
    WHEN REGEXP_CONTAINS(medium, 'push$')
         OR REGEXP_CONTAINS(medium, '(mobile|notification)')                           THEN 'Mobile Push Notifications'

    -- Everything else
    ELSE 'Unassigned'
  END AS channel_group,
  COUNT(DISTINCT session_key) AS total_sessions
FROM dec_sessions
GROUP BY channel_group
ORDER BY total_sessions DESC;
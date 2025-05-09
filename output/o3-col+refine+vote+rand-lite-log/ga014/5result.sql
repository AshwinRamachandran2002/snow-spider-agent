-- Total number of December-2020 sessions per GA4 Channel Group
WITH base AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')                                           AS ga_session_id,
    LOWER(
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'source'))                                               AS source,
    LOWER(
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
        WHERE ep.key = 'medium'))                                               AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
),
sessions AS (
  SELECT DISTINCT
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))                  AS session_key,
    CASE
      /* Direct */
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)')            THEN 'Direct'

      /* Referral */
      WHEN medium = 'referral'                                                  THEN 'Referral'

      /* Organic Search */
      WHEN medium = 'organic'
        OR REGEXP_CONTAINS(source, r'^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                                                                                 THEN 'Organic Search'

      /* Organic Social */
      WHEN REGEXP_CONTAINS(source, r'(facebook|instagram|linkedin|pinterest|tiktok|twitter|whatsapp|badoo)')
        OR medium IN ('social','social-network','social-media','sm',
                      'social network','social media')                          THEN 'Organic Social'

      /* Organic Video */
      WHEN REGEXP_CONTAINS(source, r'(youtube|vimeo|twitch|dailymotion)')
        OR REGEXP_CONTAINS(medium, r'.*video.*')                                THEN 'Organic Video'

      /* Organic Shopping */
      WHEN REGEXP_CONTAINS(source, r'(alibaba|amazon|etsy|ebay|shopify|stripe|walmart)')
        OR REGEXP_CONTAINS(source, r'google shopping')
        OR REGEXP_CONTAINS(medium, r'organic shopping')                         THEN 'Organic Shopping'

      /* Email */
      WHEN source IN ('email','e-mail','e_mail','e mail')
        OR medium IN ('email','e-mail','e_mail','e mail')                       THEN 'Email'

      /* Display */
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')     THEN 'Display'

      /* Paid Search */
      WHEN REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        AND REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                                                                                 THEN 'Paid Search'

      /* Paid Shopping */
      WHEN REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        AND (REGEXP_CONTAINS(source , r'(alibaba|amazon|etsy|ebay|shopify|stripe|walmart)')
             OR REGEXP_CONTAINS(source, r'google shopping'))                    THEN 'Paid Shopping'

      /* Paid Social */
      WHEN REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        AND REGEXP_CONTAINS(source , r'(facebook|instagram|linkedin|pinterest|tiktok|twitter|whatsapp|badoo)')
                                                                                 THEN 'Paid Social'

      /* Paid Video */
      WHEN REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        AND REGEXP_CONTAINS(source , r'(youtube|vimeo|twitch|dailymotion)')      THEN 'Paid Video'

      /* Audio */
      WHEN medium = 'audio'                                                    THEN 'Audio'

      /* Affiliates */
      WHEN medium = 'affiliate'                                                THEN 'Affiliates'

      /* SMS */
      WHEN source = 'sms' OR medium = 'sms'                                    THEN 'SMS'

      /* Mobile Push Notifications */
      WHEN RIGHT(medium, 4) = 'push'
        OR REGEXP_CONTAINS(medium, r'(mobile|notification)')                   THEN 'Mobile Push Notifications'

      /* Cross-network */
      WHEN REGEXP_CONTAINS(source, r'.*cross-network.*')
        OR REGEXP_CONTAINS(source, r'(demand gen|performance max|smart shopping)')
                                                                               THEN 'Cross-network'

      /* Fallback */
      ELSE 'Unassigned'
    END AS channel
  FROM base
  WHERE ga_session_id IS NOT NULL
)
SELECT
  channel,
  COUNT(DISTINCT session_key) AS sessions
FROM sessions
GROUP BY channel
ORDER BY sessions DESC;
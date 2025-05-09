WITH session_starts AS (
  /* All session_start events for December 2020 */
  SELECT
    traffic_source.source  AS source,
    traffic_source.medium  AS medium,
    traffic_source.name    AS campaign,
    user_pseudo_id,
    (SELECT ep.value.int_value         -- session identifier
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id'
     LIMIT 1)                         AS ga_session_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

classified AS (
  /* Map each session to a default channel group */
  SELECT
    CASE
      WHEN LOWER(source) = '(direct)'
           AND LOWER(medium) IN ('(not set)', '(none)')                   THEN 'Direct'
      WHEN LOWER(medium) = 'affiliate'                                   THEN 'Affiliates'
      WHEN LOWER(medium) = 'audio'                                       THEN 'Audio'
      WHEN LOWER(campaign) LIKE '%cross-network%'                         THEN 'Cross-network'
      WHEN REGEXP_CONTAINS(LOWER(medium), r'(.*cp.*|ppc|retargeting|paid.*)')
           THEN CASE
                  WHEN LOWER(source) IN ('baidu','bing','duckduckgo','ecosia',
                                         'google','yahoo','yandex')       THEN 'Paid Search'
                  WHEN LOWER(source) IN ('alibaba','amazon','google shopping',
                                         'shopify','etsy','ebay','stripe',
                                         'walmart')                       THEN 'Paid Shopping'
                  WHEN LOWER(source) IN ('badoo','facebook','fb','instagram',
                                         'linkedin','pinterest','tiktok',
                                         'twitter','whatsapp')            THEN 'Paid Social'
                  WHEN LOWER(source) IN ('dailymotion','disneyplus','netflix',
                                         'youtube','vimeo','twitch')       THEN 'Paid Video'
                  ELSE 'Paid Search'
                END
      WHEN LOWER(medium) IN ('display','banner','expandable',
                             'interstitial','cpm')                        THEN 'Display'
      WHEN LOWER(medium) IN ('email','e-mail','e_mail','e mail')
        OR LOWER(source) IN ('email','e-mail','e_mail','e mail')          THEN 'Email'
      WHEN LOWER(medium) = 'referral'                                     THEN 'Referral'
      WHEN LOWER(medium) = 'social'
        OR LOWER(medium) IN ('social-network','social-media','sm',
                             'social network','social media')
        OR LOWER(source) IN ('badoo','facebook','fb','instagram','linkedin',
                             'pinterest','tiktok','twitter','whatsapp')    THEN 'Organic Social'
      WHEN LOWER(medium) = 'organic'
        AND LOWER(source) IN ('alibaba','amazon','google shopping',
                              'shopify','etsy','ebay','stripe','walmart')  THEN 'Organic Shopping'
      WHEN LOWER(medium) = 'organic'
        AND LOWER(source) IN ('dailymotion','disneyplus','netflix',
                              'youtube','vimeo','twitch')                  THEN 'Organic Video'
      WHEN LOWER(medium) = 'organic'                                      THEN 'Organic Search'
      WHEN LOWER(medium) LIKE '%push'
        OR LOWER(medium) LIKE '%mobile%'
        OR LOWER(medium) LIKE '%notification%'                            THEN 'Mobile Push Notifications'
      WHEN LOWER(medium) = 'sms' OR LOWER(source) = 'sms'                 THEN 'SMS'
      ELSE 'Unassigned'
    END                                                                  AS channel,
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))           AS unique_session
  FROM session_starts
  WHERE ga_session_id IS NOT NULL
),

ranked_channels AS (
  /* Aggregate sessions and rank the channels */
  SELECT
    channel,
    COUNT(DISTINCT unique_session) AS sessions,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT unique_session) DESC) AS rnk
  FROM classified
  GROUP BY channel
)

-- Return the channel with the 4‑th highest number of sessions
SELECT
  channel,
  sessions
FROM ranked_channels
WHERE rnk = 4;
/*  Sessions per traffic‑channel – December 2020  */

WITH december_session_start AS (
  SELECT
    /* pull GA traffic attributes from the event_params array */
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'source')  AS source,

    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'medium')  AS medium,

    (SELECT ep.value.string_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'campaign') AS campaign,

    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id') AS ga_session_id,

    user_pseudo_id
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
    AND event_date BETWEEN '20201201' AND '20201231'
),

classified AS (
  SELECT
    /* Channel group classification – follows GA4 logic order */
    CASE
      /* Direct --------------------------------------------------------------*/
      WHEN LOWER(source) = '(direct)'
           AND LOWER(medium) IN ('(not set)', '(none)')                       THEN 'Direct'

      /* Cross‑network -------------------------------------------------------*/
      WHEN LOWER(campaign) LIKE '%cross-network%'                             THEN 'Cross-network'

      /* Paid Shopping -------------------------------------------------------*/
      WHEN (REGEXP_CONTAINS(LOWER(source),
             r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(LOWER(campaign),
             r'(^|[^a-df-z])(shop|shopping)'))
           AND REGEXP_CONTAINS(LOWER(medium),
             r'(cp|ppc|retargeting|paid)')                                    THEN 'Paid Shopping'

      /* Paid Search ---------------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(LOWER(medium),
             r'(cp|ppc|paid)')                                                THEN 'Paid Search'

      /* Paid Social ---------------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(LOWER(medium),
             r'(cp|ppc|retargeting|paid)')                                    THEN 'Paid Social'

      /* Paid Video ----------------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(LOWER(medium),
             r'(cp|ppc|retargeting|paid)')                                    THEN 'Paid Video'

      /* Display -------------------------------------------------------------*/
      WHEN LOWER(medium) IN ('display','banner','expandable',
                             'interstitial','cpm')                            THEN 'Display'

      /* Organic Shopping ----------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(LOWER(campaign),
             r'(^|[^a-df-z])(shop|shopping)')                                 THEN 'Organic Shopping'

      /* Organic Social ------------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR LOWER(medium) IN ('social','social-network','social-media',
                                'sm','social network','social media')         THEN 'Organic Social'

      /* Organic Video -------------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(LOWER(medium), r'video')                        THEN 'Organic Video'

      /* Organic Search ------------------------------------------------------*/
      WHEN REGEXP_CONTAINS(LOWER(source),
             r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR LOWER(medium) = 'organic'                                       THEN 'Organic Search'

      /* Referral ------------------------------------------------------------*/
      WHEN LOWER(medium) = 'referral'                                         THEN 'Referral'

      /* Email ---------------------------------------------------------------*/
      WHEN LOWER(source) IN ('email','e-mail','e_mail','e mail')
           OR LOWER(medium) IN ('email','e-mail','e_mail','e mail')           THEN 'Email'

      /* Affiliates ----------------------------------------------------------*/
      WHEN LOWER(medium) = 'affiliate'                                        THEN 'Affiliates'

      /* Audio ----------------------------------------------------------------*/
      WHEN LOWER(medium) = 'audio'                                            THEN 'Audio'

      /* SMS ------------------------------------------------------------------*/
      WHEN LOWER(source) = 'sms' OR LOWER(medium) = 'sms'                     THEN 'SMS'

      /* Mobile Push Notifications -------------------------------------------*/
      WHEN LOWER(medium) LIKE '%push'
           OR LOWER(medium) LIKE '%mobile%'
           OR LOWER(medium) LIKE '%notification%'                             THEN 'Mobile Push Notifications'

      /* Unassigned -----------------------------------------------------------*/
      ELSE 'Unassigned'
    END                                                  AS channel_group,

    /* one unique key per session                                            */
    CONCAT(user_pseudo_id,'-',CAST(ga_session_id AS STRING)) AS session_key
  FROM december_session_start
)

SELECT
  channel_group,
  COUNT(DISTINCT session_key) AS total_sessions
FROM classified
GROUP BY channel_group
ORDER BY total_sessions DESC;
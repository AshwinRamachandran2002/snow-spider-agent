/* 1️⃣  Collect all December-2020 events and keep only the session_start rows        */
/* 2️⃣  Derive Channel Grouping from source / medium / campaign                      */
/* 3️⃣  Count sessions by channel and return the 4-th highest                       */

WITH december_events AS (        /* Step-1 : UNION ALL the 31 December tables      */
    SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230"
    UNION ALL SELECT "EVENT_NAME" , "TRAFFIC_SOURCE"
      FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"
)
/* -------------------------------------------------------------------------------- */
, session_starts AS (         /* keep only session_start rows                      */
    SELECT "TRAFFIC_SOURCE"
      FROM december_events
     WHERE "EVENT_NAME" = 'session_start'
)
/* -------------------------------------------------------------------------------- */
, sessions_with_channel AS (  /* Step-2 : classify each session into a channel     */
    SELECT
        CASE
            /* Direct */
            WHEN TRIM(LOWER("TRAFFIC_SOURCE":"source"::string)) = '(direct)'
                 AND TRIM(LOWER("TRAFFIC_SOURCE":"medium"::string)) IN ('(not set)', '(none)', '') THEN 'Direct'

            /* Cross-network */
            WHEN LOWER("TRAFFIC_SOURCE":"name"::string)        LIKE '%cross-network%'                                             THEN 'Cross-network'

            /* Paid Shopping */
            WHEN (REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                  OR REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"name"::string) , '(^|[^a-df-z])(shop|shopping)'))
                 AND REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"medium"::string), '(cp|ppc|retargeting|paid)')                            THEN 'Paid Shopping'

            /* Paid Search */
            WHEN REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                 AND REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"medium"::string), '(cp|ppc|paid)')                                        THEN 'Paid Search'

            /* Paid Social */
            WHEN REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 AND REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"medium"::string), '(cp|ppc|retargeting|paid)')                             THEN 'Paid Social'

            /* Paid Video */
            WHEN REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                 AND REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"medium"::string), '(cp|ppc|retargeting|paid)')                             THEN 'Paid Video'

            /* Display */
            WHEN LOWER("TRAFFIC_SOURCE":"medium"::string)
                 IN ('display','banner','expandable','interstitial','cpm')                                                        THEN 'Display'

            /* Organic Shopping */
            WHEN (REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                  OR REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"name"::string) , '(^|[^a-df-z])(shop|shopping)'))                         THEN 'Organic Shopping'

            /* Organic Social */
            WHEN REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 OR LOWER("TRAFFIC_SOURCE":"medium"::string)
                    IN ('social','social-network','social-media','sm','social network','social media')                             THEN 'Organic Social'

            /* Organic Video */
            WHEN REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                 OR REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"medium"::string), 'video')                                                 THEN 'Organic Video'

            /* Organic Search */
            WHEN REGEXP_LIKE(LOWER("TRAFFIC_SOURCE":"source"::string) , '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 OR LOWER("TRAFFIC_SOURCE":"medium"::string) = 'organic'                                                           THEN 'Organic Search'

            /* Referral */
            WHEN LOWER("TRAFFIC_SOURCE":"medium"::string) = 'referral'                                                            THEN 'Referral'

            /* Email */
            WHEN LOWER("TRAFFIC_SOURCE":"source"::string) IN ('email','e-mail','e_mail','e mail')
              OR LOWER("TRAFFIC_SOURCE":"medium"::string) IN ('email','e-mail','e_mail','e mail')                                 THEN 'Email'

            /* Affiliates */
            WHEN LOWER("TRAFFIC_SOURCE":"medium"::string) = 'affiliate'                                                           THEN 'Affiliates'

            /* Audio */
            WHEN LOWER("TRAFFIC_SOURCE":"medium"::string) = 'audio'                                                               THEN 'Audio'

            /* SMS */
            WHEN LOWER("TRAFFIC_SOURCE":"source"::string) = 'sms'
              OR LOWER("TRAFFIC_SOURCE":"medium"::string) = 'sms'                                                                 THEN 'SMS'

            /* Mobile Push Notifications */
            WHEN LOWER("TRAFFIC_SOURCE":"medium"::string) LIKE '%push'
              OR LOWER("TRAFFIC_SOURCE":"medium"::string) LIKE '%mobile%'
              OR LOWER("TRAFFIC_SOURCE":"medium"::string) LIKE '%notification%'                                                   THEN 'Mobile Push Notifications'

            /* Unassigned */
            ELSE 'Unassigned'
        END AS channel
    FROM session_starts
)
/* -------------------------------------------------------------------------------- */
SELECT
    channel ,
    COUNT(*) AS sessions
FROM sessions_with_channel
GROUP BY channel
QUALIFY ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) = 4;
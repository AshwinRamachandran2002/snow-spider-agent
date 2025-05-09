WITH dec_events AS (   /* --- All December-2020 GA4 exports ---------------------------------- */
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201201 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201202 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201203 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201204 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201205 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201206 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201207 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201208 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201209 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201210 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201211 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201212 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201213 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201214 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201215 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201216 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201217 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201218 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201219 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201220 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201221 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201222 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201223 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201224 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201225 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201226 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201227 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201228 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201229 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201230 UNION ALL
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201231
),
session_events AS (    /* --- One row per session (event_name = session_start) --------------- */
    SELECT
        LOWER( (TRY_PARSE_JSON("TRAFFIC_SOURCE"):"medium") :: STRING )  AS medium,
        LOWER( (TRY_PARSE_JSON("TRAFFIC_SOURCE"):"source") :: STRING )  AS source,
        LOWER( (TRY_PARSE_JSON("TRAFFIC_SOURCE"):"name")   :: STRING )  AS campaign_name
    FROM dec_events
    WHERE "EVENT_NAME" = 'session_start'
),
classified AS (        /* --- Map to Default Channel Group ----------------------------------- */
    SELECT
        CASE
            WHEN source = '(direct)' AND medium IN ('(not set)', '(none)') THEN 'Direct'
            WHEN REGEXP_LIKE(campaign_name , 'cross-network')                                            THEN 'Cross-network'
            WHEN (   REGEXP_LIKE(source , '^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                   OR REGEXP_LIKE(campaign_name , '(^|[^a-df-z])(shop|shopping)') )
                 AND REGEXP_LIKE(medium , '(.*cp.*|ppc|retargeting|paid.*)')                              THEN 'Paid Shopping'
            WHEN REGEXP_LIKE(source , '^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                 AND REGEXP_LIKE(medium , '(.*cp.*|ppc|paid.*)')                                          THEN 'Paid Search'
            WHEN REGEXP_LIKE(source , '^(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)$')
                 AND REGEXP_LIKE(medium , '(.*cp.*|ppc|retargeting|paid.*)')                              THEN 'Paid Social'
            WHEN REGEXP_LIKE(source , '^(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)$')
                 AND REGEXP_LIKE(medium , '(.*cp.*|ppc|retargeting|paid.*)')                              THEN 'Paid Video'
            WHEN medium IN ('display','banner','expandable','interstitial','cpm')                        THEN 'Display'
            WHEN    REGEXP_LIKE(source , '^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                 OR REGEXP_LIKE(campaign_name , '(^|[^a-df-z])(shop|shopping)')                           THEN 'Organic Shopping'
            WHEN    REGEXP_LIKE(source , '^(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)$')
                 OR medium IN ('social','social-network','social-media','sm','social network','social media')
                                                                                                          THEN 'Organic Social'
            WHEN    REGEXP_LIKE(source , '^(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)$')
                 OR REGEXP_LIKE(medium , '.*video.*')                                                     THEN 'Organic Video'
            WHEN    REGEXP_LIKE(source , '^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                 OR medium = 'organic'                                                                   THEN 'Organic Search'
            WHEN medium = 'referral'                                                                     THEN 'Referral'
            WHEN source IN ('email','e-mail','e_mail','e mail') OR medium IN ('email','e-mail','e_mail','e mail')
                                                                                                          THEN 'Email'
            WHEN medium = 'affiliate'                                                                    THEN 'Affiliates'
            WHEN medium = 'audio'                                                                        THEN 'Audio'
            WHEN source = 'sms' OR medium = 'sms'                                                        THEN 'SMS'
            WHEN medium ILIKE '%push' OR medium ILIKE '%mobile%' OR medium ILIKE '%notification%'
                                                                                                          THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS channel_group
    FROM session_events
),
grouped AS (           /* --- Sessions per channel ------------------------------------------- */
    SELECT channel_group,
           COUNT(*) AS sessions
    FROM   classified
    GROUP  BY channel_group
)
SELECT channel_group,
       sessions
FROM (
    SELECT channel_group,
           sessions,
           ROW_NUMBER() OVER (ORDER BY sessions DESC NULLS LAST) AS rn
    FROM grouped
)
WHERE rn = 4;
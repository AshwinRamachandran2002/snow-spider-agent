/*  Total number of sessions per traffic-channel – December 2020  */

WITH ALL_DEC_EVENTS AS (      -- 1. put every December-2020 daily table into one set
    SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230"
    UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"
),

SESSION_PARAMS AS (           -- 2. take only “session_start” rows and pull source / medium / campaign
    SELECT
        ADE."USER_PSEUDO_ID",
        MAX( CASE WHEN EP.VALUE:KEY = 'ga_session_id' THEN COALESCE(EP.VALUE:INT_VALUE::STRING , EP.VALUE:STRING_VALUE) END )                 AS GA_SESSION_ID,
        MAX( CASE WHEN EP.VALUE:KEY = 'source'        THEN COALESCE(EP.VALUE:STRING_VALUE      , EP.VALUE:INT_VALUE::STRING) END )            AS SOURCE,
        MAX( CASE WHEN EP.VALUE:KEY = 'medium'        THEN COALESCE(EP.VALUE:STRING_VALUE      , EP.VALUE:INT_VALUE::STRING) END )            AS MEDIUM,
        MAX( CASE WHEN EP.VALUE:KEY = 'campaign'      THEN COALESCE(EP.VALUE:STRING_VALUE      , EP.VALUE:INT_VALUE::STRING) END )            AS CAMPAIGN
    FROM ALL_DEC_EVENTS  ADE,
         LATERAL FLATTEN( ADE."EVENT_PARAMS" )  EP
    WHERE ADE."EVENT_NAME" = 'session_start'
    GROUP BY ADE."USER_PSEUDO_ID"      -- one record per session_start row
),

CHANNEL_SESSIONS AS (         -- 3. map to default channel group
    SELECT
        CASE
            WHEN LOWER(SOURCE) = '(direct)'         AND LOWER(MEDIUM) IN ('(none)', '(not set)')                             THEN 'Direct'
            WHEN REGEXP_LIKE(LOWER(CAMPAIGN) , 'cross-network')                                                              THEN 'Cross-network'
            WHEN (REGEXP_LIKE(LOWER(SOURCE) , '\\b(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)\\b')
                  OR REGEXP_LIKE(LOWER(CAMPAIGN) , '(^.*(([^a-df-z]|^)shop|shopping).*)'))
                 AND REGEXP_LIKE(LOWER(MEDIUM) , '(cp|ppc|retargeting|paid)')                                                 THEN 'Paid Shopping'
            WHEN REGEXP_LIKE(LOWER(SOURCE) , '\\b(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)\\b')
                 AND REGEXP_LIKE(LOWER(MEDIUM) , '(cp|ppc|paid)')                                                             THEN 'Paid Search'
            WHEN REGEXP_LIKE(LOWER(SOURCE) , '\\b(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)\\b')
                 AND REGEXP_LIKE(LOWER(MEDIUM) , '(cp|ppc|retargeting|paid)')                                                 THEN 'Paid Social'
            WHEN REGEXP_LIKE(LOWER(SOURCE) , '\\b(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)\\b')
                 AND REGEXP_LIKE(LOWER(MEDIUM) , '(cp|ppc|retargeting|paid)')                                                 THEN 'Paid Video'
            WHEN LOWER(MEDIUM) IN ('display','banner','expandable','interstitial','cpm')                                     THEN 'Display'
            WHEN (REGEXP_LIKE(LOWER(SOURCE) , '\\b(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)\\b')
                  OR REGEXP_LIKE(LOWER(CAMPAIGN) , '(^.*(([^a-df-z]|^)shop|shopping).*)'))                                     THEN 'Organic Shopping'
            WHEN REGEXP_LIKE(LOWER(SOURCE) , '\\b(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)\\b')
                 OR LOWER(MEDIUM) IN ('social','social-network','social-media','sm','social network','social media')          THEN 'Organic Social'
            WHEN REGEXP_LIKE(LOWER(SOURCE) , '\\b(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)\\b')
                 OR REGEXP_LIKE(LOWER(MEDIUM) , 'video')                                                                     THEN 'Organic Video'
            WHEN REGEXP_LIKE(LOWER(SOURCE) , '\\b(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)\\b')
                 OR LOWER(MEDIUM) = 'organic'                                                                                THEN 'Organic Search'
            WHEN LOWER(MEDIUM) = 'referral'                                                                                  THEN 'Referral'
            WHEN LOWER(SOURCE) IN ('email','e-mail','e_mail','e mail')
                 OR LOWER(MEDIUM) IN ('email','e-mail','e_mail','e mail')                                                    THEN 'Email'
            WHEN LOWER(MEDIUM) = 'affiliate'                                                                                THEN 'Affiliates'
            WHEN LOWER(MEDIUM) = 'audio'                                                                                    THEN 'Audio'
            WHEN LOWER(SOURCE) = 'sms'  OR LOWER(MEDIUM) = 'sms'                                                             THEN 'SMS'
            WHEN REGEXP_LIKE(LOWER(MEDIUM) , 'push$')  OR REGEXP_LIKE(LOWER(MEDIUM) , 'mobile|notification')                 THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS CHANNEL
    FROM SESSION_PARAMS
)

SELECT
    CHANNEL,
    COUNT(*)  AS TOTAL_SESSIONS
FROM CHANNEL_SESSIONS
GROUP BY CHANNEL
ORDER BY TOTAL_SESSIONS DESC NULLS LAST;
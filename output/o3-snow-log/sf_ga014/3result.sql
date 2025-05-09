/*  Sessions per Channel Group – December-2020 (GA4 sample e-commerce)  */
WITH union_december AS (                           -- 1. combine every December table
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
/* 2. isolate “session_start” and extract source / medium / campaign / ga_session_id */
sessions AS (
    SELECT
        e."USER_PSEUDO_ID"                                             AS user_pseudo_id,
        MAX(CASE WHEN ep.value:key = 'ga_session_id'
                 THEN ep.value:value:int_value::NUMBER END)            AS ga_session_id,
        MAX(CASE WHEN ep.value:key = 'medium'
                 THEN COALESCE(ep.value:value:string_value::STRING,
                               ep.value:value:int_value::STRING) END)  AS medium,
        MAX(CASE WHEN ep.value:key = 'source'
                 THEN COALESCE(ep.value:value:string_value::STRING,
                               ep.value:value:int_value::STRING) END)  AS source,
        MAX(CASE WHEN ep.value:key = 'campaign'
                 THEN COALESCE(ep.value:value:string_value::STRING,
                               ep.value:value:int_value::STRING) END)  AS campaign
    FROM union_december e,
         LATERAL FLATTEN(INPUT => e."EVENT_PARAMS") ep
    WHERE e."EVENT_NAME" = 'session_start'
          AND ep.value:key IN ('ga_session_id','medium','source','campaign')
    GROUP BY
        e."USER_PSEUDO_ID",
        e."EVENT_TIMESTAMP"                           -- one row = one session
),
/* 3. map to default Channel Group */
classified AS (
    SELECT
        user_pseudo_id,
        ga_session_id,
        CASE
            WHEN LOWER(source) = '(direct)'
                 AND LOWER(medium) IN ('(not set)','(none)')
                 THEN 'Direct'

            WHEN LOWER(campaign) LIKE '%cross-network%'
                 THEN 'Cross-network'

            WHEN (LOWER(source) RLIKE '.*\\b(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)\\b'
                  OR LOWER(campaign) LIKE '%shop%')
                 AND LOWER(medium) RLIKE '.*(cp|ppc|retargeting|paid).*'
                 THEN 'Paid Shopping'

            WHEN LOWER(source) RLIKE '.*\\b(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)\\b'
                 AND LOWER(medium) RLIKE '.*(cp|ppc|paid).*'
                 THEN 'Paid Search'

            WHEN LOWER(source) RLIKE '.*\\b(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)\\b'
                 AND LOWER(medium) RLIKE '.*(cp|ppc|retargeting|paid).*'
                 THEN 'Paid Social'

            WHEN LOWER(source) RLIKE '.*\\b(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)\\b'
                 AND LOWER(medium) RLIKE '.*(cp|ppc|retargeting|paid).*'
                 THEN 'Paid Video'

            WHEN LOWER(medium) IN ('display','banner','expandable','interstitial','cpm')
                 THEN 'Display'

            WHEN (LOWER(source) RLIKE '.*\\b(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)\\b'
                  OR LOWER(campaign) LIKE '%shop%')
                 THEN 'Organic Shopping'

            WHEN LOWER(source) RLIKE '.*\\b(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)\\b'
                 OR LOWER(medium) IN ('social','social-network','social-media','sm','social network','social media')
                 THEN 'Organic Social'

            WHEN LOWER(source) RLIKE '.*\\b(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)\\b'
                 OR LOWER(medium) RLIKE '.*video.*'
                 THEN 'Organic Video'

            WHEN LOWER(source) RLIKE '.*\\b(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)\\b'
                 OR LOWER(medium) = 'organic'
                 THEN 'Organic Search'

            WHEN LOWER(medium) = 'referral'
                 THEN 'Referral'

            WHEN LOWER(source) IN ('email','e-mail','e_mail','e mail')
                 OR LOWER(medium) IN ('email','e-mail','e_mail','e mail')
                 THEN 'Email'

            WHEN LOWER(medium) = 'affiliate'
                 THEN 'Affiliates'

            WHEN LOWER(medium) = 'audio'
                 THEN 'Audio'

            WHEN LOWER(source) = 'sms' OR LOWER(medium) = 'sms'
                 THEN 'SMS'

            WHEN RIGHT(LOWER(medium),4) = 'push'
                 OR LOWER(medium) LIKE '%mobile%'
                 OR LOWER(medium) LIKE '%notification%'
                 THEN 'Mobile Push Notifications'

            ELSE 'Unassigned'
        END AS channel
    FROM sessions
)
/* 4. distinct session count (user_pseudo_id + ga_session_id) by channel */
SELECT
    channel,
    COUNT( DISTINCT CONCAT(user_pseudo_id,'-',ga_session_id) ) AS sessions
FROM classified
GROUP BY channel
ORDER BY sessions DESC NULLS LAST;
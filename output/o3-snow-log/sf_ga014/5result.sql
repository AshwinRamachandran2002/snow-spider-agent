/*  Sessions per GA4 Default Channel Group – December 2020  */
WITH december_events AS (          /* 1. Union every December-2020 daily table */
    SELECT * FROM (
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230" UNION ALL
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"
    )
),
session_starts AS (               /* 2. Keep only `session_start` events      */
    SELECT
        de."EVENT_TIMESTAMP",
        de."USER_PSEUDO_ID",
        de."EVENT_PARAMS"
    FROM december_events de
    WHERE de."EVENT_NAME" = 'session_start'
),
params AS (                       /* 3. Extract source / medium / campaign    */
    SELECT
        ss."EVENT_TIMESTAMP",
        ss."USER_PSEUDO_ID",
        LOWER(
            MAX(
                CASE
                    WHEN fp.value:key::string = 'source'
                    THEN COALESCE(
                             TO_VARCHAR(fp.value:value:string_value),
                             TO_VARCHAR(fp.value:value:int_value),
                             TO_VARCHAR(fp.value:value:double_value)
                         )
                END
            )
        ) AS source,
        LOWER(
            MAX(
                CASE
                    WHEN fp.value:key::string = 'medium'
                    THEN COALESCE(
                             TO_VARCHAR(fp.value:value:string_value),
                             TO_VARCHAR(fp.value:value:int_value),
                             TO_VARCHAR(fp.value:value:double_value)
                         )
                END
            )
        ) AS medium,
        LOWER(
            MAX(
                CASE
                    WHEN fp.value:key::string = 'campaign'
                    THEN COALESCE(
                             TO_VARCHAR(fp.value:value:string_value),
                             TO_VARCHAR(fp.value:value:int_value),
                             TO_VARCHAR(fp.value:value:double_value)
                         )
                END
            )
        ) AS campaign
    FROM session_starts ss,
         LATERAL FLATTEN ( INPUT => ss."EVENT_PARAMS" ) fp
    GROUP BY ss."EVENT_TIMESTAMP",
             ss."USER_PSEUDO_ID"
),
classified AS (                   /* 4. Map to Default Channel Group          */
    SELECT
        CASE
            WHEN source = '(direct)'
                 AND medium IN ('(not set)', '(none)')
                 THEN 'Direct'
            WHEN campaign IS NOT NULL
                 AND campaign LIKE '%cross-network%'
                 THEN 'Cross-network'
            WHEN (REGEXP_LIKE(source, '^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                  OR REGEXP_LIKE(campaign, '(([^a-df-z]|^)shop|shopping)'))
                 AND REGEXP_LIKE(medium, '(cp|ppc|retargeting|paid)')
                 THEN 'Paid Shopping'
            WHEN REGEXP_LIKE(source, '^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                 AND REGEXP_LIKE(medium, '(cp|ppc|paid)')
                 THEN 'Paid Search'
            WHEN REGEXP_LIKE(source, '^(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)$')
                 AND REGEXP_LIKE(medium, '(cp|ppc|retargeting|paid)')
                 THEN 'Paid Social'
            WHEN REGEXP_LIKE(source, '^(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)$')
                 AND REGEXP_LIKE(medium, '(cp|ppc|retargeting|paid)')
                 THEN 'Paid Video'
            WHEN medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm')
                 THEN 'Display'
            WHEN (REGEXP_LIKE(source, '^(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)$')
                  OR REGEXP_LIKE(campaign, '(([^a-df-z]|^)shop|shopping)'))
                 THEN 'Organic Shopping'
            WHEN REGEXP_LIKE(source, '^(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)$')
                 OR medium IN ('social','social-network','social-media','sm','social network','social media')
                 THEN 'Organic Social'
            WHEN REGEXP_LIKE(source, '^(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)$')
                 OR REGEXP_LIKE(medium, 'video')
                 THEN 'Organic Video'
            WHEN REGEXP_LIKE(source, '^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$')
                 OR medium = 'organic'
                 THEN 'Organic Search'
            WHEN medium = 'referral'
                 THEN 'Referral'
            WHEN source IN ('email', 'e-mail', 'e_mail', 'e mail')
                 OR medium IN ('email', 'e-mail', 'e_mail', 'e mail')
                 THEN 'Email'
            WHEN medium = 'affiliate'
                 THEN 'Affiliates'
            WHEN medium = 'audio'
                 THEN 'Audio'
            WHEN source = 'sms' OR medium = 'sms'
                 THEN 'SMS'
            WHEN REGEXP_LIKE(medium, 'push$')
                 OR REGEXP_LIKE(medium, 'mobile')
                 OR REGEXP_LIKE(medium, 'notification')
                 THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END AS channel
    FROM params
)
SELECT                              /* 5. Aggregate sessions by channel        */
    channel,
    COUNT(*) AS total_sessions
FROM classified
GROUP BY channel
ORDER BY total_sessions DESC NULLS LAST;
/*  Sessions by default channel group – December 2020
    “Session” = one `session_start` event, counted once per row.
*/
WITH december_events AS (        -- 1.  Bring in every December 2020 table
        SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201201
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201202
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201203
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201204
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201205
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201206
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201207
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201208
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201209
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201210
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201211
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201212
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201213
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201214
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201215
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201216
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201217
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201218
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201219
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201220
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201221
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201222
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201223
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201224
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201225
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201226
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201227
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201228
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201229
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201230
 UNION ALL SELECT * FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201231
),
december_sessions AS (           -- 2.  Keep only session starts & pull source / medium / campaign
    SELECT
        LOWER( "TRAFFIC_SOURCE":"source"::STRING )   AS src,
        LOWER( "TRAFFIC_SOURCE":"medium"::STRING )   AS med,
        LOWER( "TRAFFIC_SOURCE":"name"::STRING )     AS cmp
    FROM december_events
    WHERE "EVENT_NAME" = 'session_start'
),
channelized AS (                 -- 3.  Apply Google-style default channel-grouping rules
    SELECT
        CASE
            /* Direct */
            WHEN src = '(direct)'
                 AND med IN ('(not set)', '(none)', '')                            THEN 'Direct'

            /* Cross-network */
            WHEN cmp  LIKE '%cross-network%'                                        THEN 'Cross-network'

            /* Paid Shopping / Organic Shopping */
            WHEN REGEXP_LIKE(src, 'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
                 AND REGEXP_LIKE(med, 'cp|ppc|retargeting|paid')                    THEN 'Paid Shopping'
            WHEN REGEXP_LIKE(src, 'alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart')
                 OR  REGEXP_LIKE(cmp, '(^|[^a-df-z])(shop|shopping)')               THEN 'Organic Shopping'

            /* Paid Search / Organic Search */
            WHEN REGEXP_LIKE(src, 'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                 AND REGEXP_LIKE(med, 'cp|ppc|paid')                               THEN 'Paid Search'
            WHEN REGEXP_LIKE(src, 'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                 OR  med = 'organic'                                               THEN 'Organic Search'

            /* Paid Social / Organic Social */
            WHEN REGEXP_LIKE(src, 'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                 AND REGEXP_LIKE(med, 'cp|ppc|retargeting|paid')                    THEN 'Paid Social'
            WHEN REGEXP_LIKE(src, 'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                 OR  med IN ('social','social-network','social-media','sm','social network','social media')
                                                                                    THEN 'Organic Social'

            /* Paid Video / Organic Video */
            WHEN REGEXP_LIKE(src, 'dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
                 AND REGEXP_LIKE(med, 'cp|ppc|retargeting|paid')                    THEN 'Paid Video'
            WHEN REGEXP_LIKE(src, 'dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
                 OR  REGEXP_LIKE(med, 'video')                                     THEN 'Organic Video'

            /* Display */
            WHEN med IN ('display','banner','expandable','interstitial','cpm')      THEN 'Display'

            /* Affiliates, Audio, Email, SMS, Mobile Push */
            WHEN med = 'affiliate'                                                 THEN 'Affiliates'
            WHEN med = 'audio'                                                    THEN 'Audio'
            WHEN med IN ('email','e-mail','e_mail','e mail')
              OR src IN ('email','e-mail','e_mail','e mail')                       THEN 'Email'
            WHEN med = 'sms'  OR src = 'sms'                                      THEN 'SMS'
            WHEN RIGHT(med,4) = 'push' OR med LIKE '%mobile%' OR med LIKE '%notification%'
                                                                                    THEN 'Mobile Push Notifications'

            /* Referral */
            WHEN med = 'referral'                                                 THEN 'Referral'

            /* Fallback */
            ELSE 'Unassigned'
        END AS channel_group
    FROM december_sessions
),
channel_totals AS (              -- 4.  Sessions per channel
    SELECT
        channel_group,
        COUNT(*) AS sessions
    FROM channelized
    GROUP BY channel_group
)
SELECT
    channel_group,
    sessions,
    ROW_NUMBER() OVER (ORDER BY sessions DESC NULLS LAST) AS channel_rank
FROM channel_totals
ORDER BY channel_rank;
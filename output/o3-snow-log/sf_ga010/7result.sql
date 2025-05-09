/* 1) Collect all rows from every December-2020 event table
   2) Keep only session_start events (each row = one session)
   3) Derive the Channel Group from source/medium/campaign
   4) Rank channels by session count and return the 4-th highest                     */

WITH dec_events AS (
    SELECT "TRAFFIC_SOURCE","EVENT_NAME"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201201"  UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201202" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201203" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201204" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201205" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201206" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201207" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201208" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201209" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201210" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201211" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201212" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201213" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201214" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201215" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201216" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201217" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201218" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201219" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201220" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201221" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201222" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201223" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201224" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201225" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201226" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201227" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201228" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201229" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201230" UNION ALL
    SELECT "TRAFFIC_SOURCE","EVENT_NAME" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20201231"
),

/* keep only one row per session (= session_start event) */
session_rows AS (
    SELECT
        "TRAFFIC_SOURCE":"source"::STRING   AS src,
        "TRAFFIC_SOURCE":"medium"::STRING   AS med,
        "TRAFFIC_SOURCE":"name"::STRING     AS camp
    FROM dec_events
    WHERE "EVENT_NAME" = 'session_start'
),

/* map GA4 source / medium / campaign to Channel Grouping */
sessions_by_channel AS (
    SELECT
        CASE
            WHEN src = '(direct)'
                 AND med IN ('(not set)','(none)','')                  THEN 'Direct'

            WHEN REGEXP_LIKE(camp,'cross-network','i')                THEN 'Cross-network'

            WHEN ( REGEXP_LIKE(src,'^(alibaba|amazon|google *shopping|shopify|etsy|ebay|stripe|walmart)$','i')
                   OR REGEXP_LIKE(camp,'(^|[^a-df-z])(shop|shopping)','i')     )
                 AND REGEXP_LIKE(med,'(cp|ppc|retargeting|paid)','i') THEN 'Paid Shopping'

            WHEN REGEXP_LIKE(src,'^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$','i')
                 AND REGEXP_LIKE(med,'(cp|ppc|paid)','i')             THEN 'Paid Search'

            WHEN REGEXP_LIKE(src,'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)','i')
                 AND REGEXP_LIKE(med,'(cp|ppc|retargeting|paid)','i') THEN 'Paid Social'

            WHEN REGEXP_LIKE(src,'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)','i')
                 AND REGEXP_LIKE(med,'(cp|ppc|retargeting|paid)','i') THEN 'Paid Video'

            WHEN med IN ('display','banner','expandable','interstitial','cpm')
                                                                  THEN 'Display'

            WHEN ( REGEXP_LIKE(src,'^(alibaba|amazon|google *shopping|shopify|etsy|ebay|stripe|walmart)$','i')
                   OR REGEXP_LIKE(camp,'(^|[^a-df-z])(shop|shopping)','i') )
                                                                  THEN 'Organic Shopping'

            WHEN REGEXP_LIKE(src,'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)','i')
                 OR med IN ('social','social-network','social-media','sm','social network','social media')
                                                                  THEN 'Organic Social'

            WHEN REGEXP_LIKE(src,'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)','i')
                 OR REGEXP_LIKE(med,'video','i')                       THEN 'Organic Video'

            WHEN REGEXP_LIKE(src,'^(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)$','i')
                 OR med = 'organic'                                    THEN 'Organic Search'

            WHEN med = 'referral'                                      THEN 'Referral'
            WHEN src IN ('email','e-mail','e_mail','e mail')
                 OR med IN ('email','e-mail','e_mail','e mail')        THEN 'Email'
            WHEN med = 'affiliate'                                     THEN 'Affiliates'
            WHEN med = 'audio'                                         THEN 'Audio'
            WHEN src = 'sms' OR med = 'sms'                            THEN 'SMS'
            WHEN REGEXP_LIKE(med,'push','i')
                 OR REGEXP_LIKE(med,'mobile|notification','i')         THEN 'Mobile Push Notifications'
            ELSE 'Unassigned'
        END                                                         AS channel_group
    FROM session_rows
)

/* rank channels by sessions and return the 4-th */
SELECT channel_group,
       COUNT(*) AS sessions
FROM sessions_by_channel
GROUP BY channel_group
QUALIFY ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) = 4;
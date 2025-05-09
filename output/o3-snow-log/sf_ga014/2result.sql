/*  Total number of GA4 sessions by traffic-channel – December 2020  */

WITH all_dec_events AS (  ------------------------------------------------------------------
    SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201201
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201202
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201203
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201204
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201205
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201206
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201207
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201208
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201209
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201210
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201211
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201212
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201213
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201214
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201215
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201216
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201217
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201218
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201219
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201220
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201221
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201222
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201223
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201224
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201225
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201226
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201227
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201228
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201229
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201230
    UNION ALL SELECT "EVENT_NAME","EVENT_PARAMS" FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE.EVENTS_20201231
),

/* 2. isolate session_start events and extract source / medium / campaign ------------------*/
session_rows AS (
    SELECT
        seq4()                      AS sess_row_id,   -- unique per row
        "EVENT_PARAMS"
    FROM all_dec_events
    WHERE "EVENT_NAME" = 'session_start'
),

sessions AS (
    SELECT
        sess_row_id,
        COALESCE(
            MAX(CASE WHEN ep.value:"key" = 'source'
                     THEN COALESCE(ep.value:"string_value",ep.value:"int_value")::string END),
            '(direct)'
        ) AS src,
        COALESCE(
            MAX(CASE WHEN ep.value:"key" = 'medium'
                     THEN COALESCE(ep.value:"string_value",ep.value:"int_value")::string END),
            '(none)'
        ) AS med,
        MAX(CASE WHEN ep.value:"key" = 'campaign'
                 THEN COALESCE(ep.value:"string_value",ep.value:"int_value")::string END) AS camp
    FROM session_rows sr,
         LATERAL FLATTEN(input => sr."EVENT_PARAMS") ep
    GROUP BY sess_row_id
),

/* 3. GA4 default-channel grouping ---------------------------------------------------------*/
classified AS (
    SELECT
        CASE
            WHEN src = '(direct)' AND med IN ('(not set)','(none)','')                               THEN 'Direct'
            WHEN REGEXP_LIKE(camp,'(?i)cross-network')                                               THEN 'Cross-network'

            WHEN ( (REGEXP_LIKE(src,'(?i)alibaba|amazon|google[\\s]?shopping|shopify|etsy|ebay|stripe|walmart')
                    OR REGEXP_LIKE(camp,'(?i)(^|[^a-df-z])shop|shopping'))
                   AND REGEXP_LIKE(med,'(?i)(cp|ppc|retargeting|paid)') )                             THEN 'Paid Shopping'

            WHEN REGEXP_LIKE(src,'(?i)baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                 AND REGEXP_LIKE(med,'(?i)(cp|ppc|paid)')                                             THEN 'Paid Search'

            WHEN REGEXP_LIKE(src,'(?i)badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                 AND REGEXP_LIKE(med,'(?i)(cp|ppc|retargeting|paid)')                                  THEN 'Paid Social'

            WHEN REGEXP_LIKE(src,'(?i)dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
                 AND REGEXP_LIKE(med,'(?i)(cp|ppc|retargeting|paid)')                                  THEN 'Paid Video'

            WHEN LOWER(med) IN ('display','banner','expandable','interstitial','cpm')                 THEN 'Display'

            WHEN (REGEXP_LIKE(src,'(?i)alibaba|amazon|google[\\s]?shopping|shopify|etsy|ebay|stripe|walmart')
                  OR REGEXP_LIKE(camp,'(?i)(^|[^a-df-z])shop|shopping'))                               THEN 'Organic Shopping'

            WHEN REGEXP_LIKE(src,'(?i)badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
                 OR LOWER(med) IN ('social','social-network','social-media','sm',
                                   'social network','social media')                                   THEN 'Organic Social'

            WHEN REGEXP_LIKE(src,'(?i)dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
                 OR REGEXP_LIKE(med,'(?i)video')                                                       THEN 'Organic Video'

            WHEN REGEXP_LIKE(src,'(?i)baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
                 OR med = 'organic'                                                                   THEN 'Organic Search'

            WHEN med = 'referral'                                                                     THEN 'Referral'

            WHEN LOWER(src) IN ('email','e-mail','e_mail','e mail')
                 OR LOWER(med) IN ('email','e-mail','e_mail','e mail')                                 THEN 'Email'

            WHEN med = 'affiliate'                                                                    THEN 'Affiliates'
            WHEN med = 'audio'                                                                        THEN 'Audio'
            WHEN src = 'sms' OR med = 'sms'                                                           THEN 'SMS'

            WHEN SUBSTR(med,-4) = 'push'
                 OR med ILIKE '%mobile%'
                 OR med ILIKE '%notification%'                                                         THEN 'Mobile Push Notifications'

            ELSE 'Unassigned'
        END                   AS traffic_channel
    FROM sessions
)

/* 4. deliver counts -----------------------------------------------------------------------*/
SELECT
    traffic_channel,
    COUNT(*) AS total_sessions
FROM classified
GROUP BY traffic_channel
ORDER BY total_sessions DESC NULLS LAST;
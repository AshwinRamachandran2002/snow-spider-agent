-- 4th‑largest channel (by number of sessions) for December 2020
WITH dec_sessions AS (  -- one row = one session (session_start event)
  SELECT
    user_pseudo_id,
    ( SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id')      AS ga_session_id,
    -- --- traffic‑source fields ------------
    LOWER(traffic_source.source)  AS src,
    LOWER(traffic_source.medium)  AS med
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

classified AS (         -- apply (simplified) GA4 default‑channel logic
  SELECT
    CASE
      WHEN src = '(direct)' AND med IN ('(not set)', '(none)')                 THEN 'Direct'
      WHEN med = 'referral'                                                   THEN 'Referral'
      WHEN med = 'organic'
           OR src IN ('google','bing','yahoo','baidu','duckduckgo','ecosia','yandex')
                                                                             THEN 'Organic Search'
      WHEN REGEXP_CONTAINS(med , r'(email|e-mail|e_mail|e mail)')
        OR REGEXP_CONTAINS(src , r'(email|e-mail|e_mail|e mail)')             THEN 'Email'
      WHEN REGEXP_CONTAINS(med , r'(social|social[- _]?network|social[- _]?media|sm)')
        OR REGEXP_CONTAINS(src , r'(facebook|instagram|twitter|linkedin|pinterest|tiktok|whatsapp|badoo|fb)')
                                                                             THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(med , r'(cpc|ppc|paid|cp)')
        AND src IN ('google','bing','yahoo','baidu','duckduckgo','ecosia','yandex')
                                                                             THEN 'Paid Search'
      ELSE 'Unassigned'
    END AS channel
  FROM dec_sessions
),

channel_totals AS (      -- count sessions per channel
  SELECT
    channel,
    COUNT(*) AS sessions
  FROM classified
  GROUP BY channel
),

ranked AS (              -- rank channels by sessions
  SELECT
    channel,
    sessions,
    DENSE_RANK() OVER (ORDER BY sessions DESC) AS rnk
  FROM channel_totals
)

-- return the channel(s) in 4th place
SELECT channel,
       sessions
FROM   ranked
WHERE  rnk = 4;
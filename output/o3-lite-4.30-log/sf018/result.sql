WITH send_counts AS (
    SELECT COUNT(*) AS total_notifications_sent
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW"
    WHERE "TIME" >= 1685635200   -- 2023‑06‑01 08:00:00 UTC
      AND "TIME" <  1685638800   -- 2023‑06‑01 09:00:00 UTC
), 
open_counts AS (
    SELECT COUNT(*) AS total_notifications_opened
    FROM "BRAZE_USER_EVENT_DEMO_DATASET"."PUBLIC"."USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW"
    WHERE "TIME" >= 1685635200
      AND "TIME" <  1685638800
)
SELECT 
    TO_TIMESTAMP_NTZ(1685635200) AS window_start,
    TO_TIMESTAMP_NTZ(1685638800) AS window_end,
    s.total_notifications_sent,
    o.total_notifications_opened,
    ROUND(o.total_notifications_opened / NULLIF(s.total_notifications_sent, 0), 4) AS open_rate
FROM send_counts s, open_counts o;
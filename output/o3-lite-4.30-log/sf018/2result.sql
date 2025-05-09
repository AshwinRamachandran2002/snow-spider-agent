WITH win AS (   -- one‑hour window on 1‑Jun‑2023
    SELECT
        TO_TIMESTAMP_LTZ('2023-06-01 08:00:00') AS window_start_ts,
        TO_TIMESTAMP_LTZ('2023-06-01 09:00:00') AS window_end_ts,
        1685606400                              AS window_start_epoch,
        1685610000                              AS window_end_epoch
),
send_ct AS (     -- total sent notifications
    SELECT COUNT(*) AS total_notifications_sent
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_SEND_VIEW s
    JOIN win w
      ON s."TIME" BETWEEN w.window_start_epoch AND w.window_end_epoch
),
open_ct AS (     -- total opened notifications
    SELECT COUNT(*) AS total_notifications_opened
    FROM BRAZE_USER_EVENT_DEMO_DATASET.PUBLIC.USERS_MESSAGES_PUSHNOTIFICATION_OPEN_VIEW o
    JOIN win w
      ON o."TIME" BETWEEN w.window_start_epoch AND w.window_end_epoch
)
SELECT
    TO_CHAR((SELECT window_start_ts FROM win), 'YYYY-MM-DD HH24:MI:SS') AS window_start,
    TO_CHAR((SELECT window_end_ts   FROM win), 'YYYY-MM-DD HH24:MI:SS') AS window_end,
    s.total_notifications_sent,
    o.total_notifications_opened,
    CASE
        WHEN s.total_notifications_sent = 0 THEN 0
        ELSE ROUND(o.total_notifications_opened::FLOAT / s.total_notifications_sent, 4)
    END AS open_rate
FROM send_ct s
CROSS JOIN open_ct o;
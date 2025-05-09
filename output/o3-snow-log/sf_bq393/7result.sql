WITH activity_months AS (      -- every (user , active month) pair up to 10-Sep-2024
    SELECT DISTINCT
        "by"                                              AS user_id,
        DATE_TRUNC('month', TO_TIMESTAMP("time"))         AS act_month
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "by" IS NOT NULL
      AND TO_TIMESTAMP("time") < '2024-09-11'::timestamp  -- keep data up to 10-Sep-2024
),

user_summary AS (            -- first/last month, span length, gaps & inactivity
    SELECT
        user_id,
        MIN(act_month)                                                       AS first_month,
        MAX(act_month)                                                       AS last_month,
        COUNT(*)                                                             AS active_month_cnt,
        DATEDIFF(month, MIN(act_month), MAX(act_month)) + 1                  AS span_month_cnt,
        DATEDIFF(month,
                 MAX(act_month),
                 DATE_TRUNC('month', '2024-09-10'::date))                    AS months_inactive_after
    FROM activity_months
    GROUP BY user_id
),

candidates AS (              -- users with at least one missing month inside span
    SELECT
        user_id,
        span_month_cnt
    FROM user_summary
    WHERE span_month_cnt > active_month_cnt          -- gap within active span
      AND months_inactive_after >= 1                 -- inactive after last active month
)

SELECT
    user_id,
    span_month_cnt AS month_number
FROM candidates
QUALIFY ROW_NUMBER() OVER (ORDER BY span_month_cnt DESC NULLS LAST, user_id) = 1;
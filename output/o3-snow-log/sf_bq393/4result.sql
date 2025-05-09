/* ----------------------------------------------------------
   Identify the user who was active for the largest number of
   months (counted from their first active month) but shows
   at least one “missing” month of activity inside that span
   and no activity after their last month (data considered
   only up to 2024-09-10).
----------------------------------------------------------*/
WITH filtered AS (          -- keep rows up to 2024-09-10
    SELECT
        "by"                                        AS user_id,
        DATE_TRUNC('month', TO_TIMESTAMP("time"))   AS activity_month
    FROM HACKER_NEWS.HACKER_NEWS.FULL
    WHERE "by"   IS NOT NULL
      AND "time" IS NOT NULL
      AND "time" <= DATE_PART(
                        epoch_second,
                        TO_TIMESTAMP_NTZ('2024-09-10 23:59:59')
                    )
),  -- one record per user per month
user_months AS (
    SELECT DISTINCT user_id, activity_month
    FROM filtered
),  -- span (first, last, #months) for every user
user_span AS (
    SELECT
        user_id,
        MIN(activity_month)                                   AS first_month,
        MAX(activity_month)                                   AS last_month,
        DATEDIFF('month', MIN(activity_month), MAX(activity_month)) + 1
                                                             AS total_months
    FROM user_months
    GROUP BY user_id
),  -- generate every expected month inside the span
expected_months AS (
    SELECT
        us.user_id,
        DATEADD('month', seq.value, us.first_month) AS expected_month
    FROM user_span us,
         LATERAL FLATTEN(
             input => ARRAY_GENERATE_RANGE(0, us.total_months - 1)
         ) seq
),  -- find users that have at least one missing month
missing_months AS (
    SELECT em.user_id
    FROM expected_months em
    LEFT JOIN user_months um
           ON um.user_id = em.user_id
          AND um.activity_month = em.expected_month
    WHERE um.activity_month IS NULL                -- gap found
    GROUP BY em.user_id
),  -- candidate users = have a gap inside their active span
candidate_users AS (
    SELECT us.user_id, us.total_months
    FROM   user_span us
    JOIN   missing_months mm
           ON us.user_id = mm.user_id
)
SELECT
    user_id      AS "USER_ID",
    total_months AS "MONTH_NUMBER"
FROM candidate_users
ORDER BY total_months DESC NULLS LAST     -- highest span first
LIMIT 1;
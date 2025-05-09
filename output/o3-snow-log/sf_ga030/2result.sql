WITH all_sessions AS (   -- every “session_start” event in the whole data set
    SELECT "user_pseudo_id"                         AS user_id ,
           TO_DATE("event_date",'YYYYMMDD')         AS event_dt
    FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180612 WHERE "event_name" = 'session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180613 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180614 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180615 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180616 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180617 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180618 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180619 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180620 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180621 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180622 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180623 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180624 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180625 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180626 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180627 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180628 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180629 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180630 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180701 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180702 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180703 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180704 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180705 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180706 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180707 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180708 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180709 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180710 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180711 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180712 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180713 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180714 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180715 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180716 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180717 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180718 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180719 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180720 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180721 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180722 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180723 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180724 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180725 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180726 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180727 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180728 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180729 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180730 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180731 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180801 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180802 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180803 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180804 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180805 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180806 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180807 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180814 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180815 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180816 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180817 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180818 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180819 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180820 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180821 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180822 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180823 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180824 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180825 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180826 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180827 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180828 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180829 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180830 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180831 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180901 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180902 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180903 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180904 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180905 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180906 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180907 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180908 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180909 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180910 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180911 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180912 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180913 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180914 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180915 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180916 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180917 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180918 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180919 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180920 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180921 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180922 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180923 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180924 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180925 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180926 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180927 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180928 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180929 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180930 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20181001 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20181002 WHERE "event_name"='session_start'
    UNION ALL SELECT "user_pseudo_id",TO_DATE("event_date",'YYYYMMDD') FROM FIREBASE.ANALYTICS_153293282.EVENTS_20181003 WHERE "event_name"='session_start'
),

-- first session for every user
user_first_session AS (
    SELECT user_id,
           MIN(event_dt) AS first_session_date
    FROM all_sessions
    GROUP BY user_id
),

-- keep only users whose first session was on/after 2-Jul-2018
filtered_users AS (
    SELECT  user_id,
            first_session_date,
            DATE_TRUNC('week', first_session_date) AS cohort_start
    FROM    user_first_session
    WHERE   first_session_date >= '2018-07-02'
),

-- size of each weekly cohort
cohort_size AS (
    SELECT cohort_start,
           COUNT(DISTINCT user_id) AS cohort_users
    FROM   filtered_users
    GROUP BY cohort_start
),

-- users who came back in the 4-th week (days 21-27)
returns_week4 AS (
    SELECT DISTINCT
           f.cohort_start,
           f.user_id
    FROM   filtered_users f
    JOIN   all_sessions  s
           ON  s.user_id = f.user_id
           AND s.event_dt >= f.cohort_start + INTERVAL '21 DAY'
           AND s.event_dt <  f.cohort_start + INTERVAL '28 DAY'
),

-- retention rate for week-4
cohort_retention AS (
    SELECT  c.cohort_start,
            COUNT(DISTINCT r.user_id)                     AS retained_users_week4,
            c.cohort_users,
            ROUND(COUNT(DISTINCT r.user_id)*100.0 / c.cohort_users ,4) AS retention_rate
    FROM    cohort_size c
    LEFT JOIN returns_week4 r
           ON c.cohort_start = r.cohort_start
    GROUP BY c.cohort_start, c.cohort_users
),

best_cohort AS (
    SELECT cohort_start
    FROM   cohort_retention
    ORDER BY retention_rate DESC NULLS LAST
    LIMIT 1
)

SELECT TO_CHAR(cohort_start,'YYYY-MM-DD') AS "best_cohort_monday"
FROM   best_cohort;
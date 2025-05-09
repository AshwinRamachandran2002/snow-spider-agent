/*--------------------------------------------------------------------
   Percentage of users who installed in Aug–Sep 2018 and either
   (a) never generated an “app_remove” event or
   (b) generated their first “app_remove” event more than 7 days
       after their “first_open” install event
--------------------------------------------------------------------*/
WITH all_events AS (
    SELECT "user_pseudo_id",
           "event_name",
           "event_timestamp",
           "event_date"
    FROM (
        /* ----------  AUGUST 2018  ---------- */
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831" UNION ALL
        
        /* ----------  SEPTEMBER 2018  ---------- */
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930" UNION ALL
        
        /* ----------  OCTOBER 2018 (to capture 7-day uninstall window)  ---------- */
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002" UNION ALL
        SELECT "user_pseudo_id","event_name","event_timestamp","event_date" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
    ) AS unioned
    WHERE "event_name" IN ('first_open','app_remove')
),

/* ------------- installs during Aug-Sep 2018 ---------------- */
installs AS (
    SELECT
        "user_pseudo_id",
        MIN("event_timestamp") AS install_ts   -- earliest install in period
    FROM all_events
    WHERE "event_name"   = 'first_open'
      AND "event_date" BETWEEN '20180801' AND '20180930'
    GROUP BY "user_pseudo_id"
),

/* ------------- earliest uninstall after the install -------- */
uninstalls AS (
    SELECT
        e."user_pseudo_id",
        MIN(e."event_timestamp") AS uninstall_ts
    FROM all_events       e
    JOIN installs         i
      ON e."user_pseudo_id" = i."user_pseudo_id"
    WHERE e."event_name"      = 'app_remove'
      AND e."event_timestamp" >= i.install_ts   -- only consider uninstalls after install
    GROUP BY e."user_pseudo_id"
),

/* ------------- classify each user -------------------------- */
evaluation AS (
    SELECT
        i."user_pseudo_id",
        CASE
            WHEN u.uninstall_ts IS NULL THEN 1                                   -- never uninstalled
            WHEN DATEDIFF(
                    'day',
                    TO_TIMESTAMP_LTZ(i.install_ts / 1000000),
                    TO_TIMESTAMP_LTZ(u.uninstall_ts / 1000000)
                 ) > 7                       THEN 1                               -- uninstall after 7 days
            ELSE 0                                                               -- uninstalled within 7 days
        END AS kept_flag
    FROM installs i
    LEFT JOIN uninstalls u
           ON i."user_pseudo_id" = u."user_pseudo_id"
),

/* ------------- aggregate ----------------------------------- */
agg AS (
    SELECT
        COUNT(*)            AS total_users,
        SUM(kept_flag)      AS kept_users
    FROM evaluation
)

/* ------------- final percentage ---------------------------- */
SELECT
    ROUND( (kept_users * 100.0) / total_users , 4) 
        AS "PCT_USERS_NOT_UNINSTALLED_WITHIN_7_DAYS"
FROM agg;
/*-----------------------------------------------------------
  Percentage of users who installed during Aug-Sep 2018 and
  either never un-installed or un-installed only after 7 days.
-----------------------------------------------------------*/
WITH
/* ---------- 1. ALL EVENTS (Aug-Sep 2018 + 1-3 Oct) ---------- */
events_aug_sep AS (
    SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180829"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180830"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180831"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181002"
    UNION ALL SELECT "event_timestamp","user_pseudo_id","event_name" FROM FIREBASE.ANALYTICS_153293282."EVENTS_20181003"
),
/* ---------- 2. FIRST INSTALL PER USER -------------------- */
installs AS (
    SELECT "user_pseudo_id",
           MIN("event_timestamp") AS install_ts
    FROM events_aug_sep
    WHERE "event_name" = 'first_open'
    GROUP BY "user_pseudo_id"
),
/* ---------- 3. FIRST UN-INSTALL PER USER ----------------- */
uninstalls AS (
    SELECT "user_pseudo_id",
           MIN("event_timestamp") AS uninstall_ts
    FROM events_aug_sep
    WHERE "event_name" = 'app_remove'
    GROUP BY "user_pseudo_id"
),
/* ---------- 4. CLASSIFY RETENTION ------------------------ */
combined AS (
    SELECT  i."user_pseudo_id",
            i.install_ts,
            u.uninstall_ts,
            CASE
                 WHEN u.uninstall_ts IS NULL                                THEN 1
                 WHEN u.uninstall_ts <  i.install_ts                        THEN 1
                 WHEN (u.uninstall_ts - i.install_ts)/1000000.0/86400 > 7   THEN 1
                 ELSE 0
            END AS retained_flag
    FROM installs i
    LEFT JOIN uninstalls u
           ON i."user_pseudo_id" = u."user_pseudo_id"
)
/* ---------- 5. FINAL PERCENTAGE -------------------------- */
SELECT
    ROUND(100.0 * SUM(retained_flag) / COUNT(*), 4) AS "PCT_RETAINED_OR_NEVER_UNINSTALLED"
FROM combined;
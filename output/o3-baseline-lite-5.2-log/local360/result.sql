WITH first_detail AS (
    /* 1.  1st “/detail” click or “/complete” conversion time per session */
    SELECT
        session,
        MIN(stamp) AS first_detail_stamp
    FROM activity_log
    WHERE path LIKE '/detail%'        -- click on a detail page
       OR path LIKE '/complete%'      -- conversion/complete page
    GROUP BY session
),
pre_events AS (
    /* 2.  Events that happened BEFORE the above time and have a non‑empty search_type */
    SELECT
        a.session,
        a.path,
        a.search_type,
        a.stamp
    FROM activity_log AS a
    JOIN first_detail AS f
      ON a.session = f.session
     AND a.stamp  < f.first_detail_stamp
    WHERE a.search_type IS NOT NULL
      AND a.search_type <> ''
),
cnts AS (
    /* 3.  How many such events per session */
    SELECT
        session,
        COUNT(*) AS cnt
    FROM pre_events
    GROUP BY session
),
mincnt AS (
    /* 4.  The minimum count value */
    SELECT MIN(cnt) AS min_cnt FROM cnts
)
/* 5.  Sessions whose count equals the minimum, with their paths & search_types */
SELECT
    p.session,
    p.path,
    p.search_type
FROM pre_events AS p
JOIN cnts     AS c ON p.session = c.session
JOIN mincnt   AS m ON c.cnt     = m.min_cnt
ORDER BY
    p.session,
    p.stamp;
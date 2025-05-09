WITH yash_id AS (
    -- Yash Chopra’s person‑id
    SELECT PID
    FROM Person
    WHERE TRIM(Name) = 'Yash Chopra'
),
actor_yash_counts AS (
    /* films in which an actor appeared that were directed by Yash Chopra */
    SELECT mc.PID AS actor_pid,
           COUNT(*) AS yash_cnt
    FROM M_Cast     mc
    JOIN M_Director md  ON mc.MID = md.MID
    JOIN yash_id    y   ON md.PID = y.PID
    GROUP BY mc.PID
),
actor_director_counts AS (
    /* for every actor–director pair, count shared films */
    SELECT mc.PID  AS actor_pid,
           md.PID  AS director_pid,
           COUNT(*) AS dir_cnt
    FROM M_Cast     mc
    JOIN M_Director md ON mc.MID = md.MID
    GROUP BY mc.PID, md.PID
),
actor_other_max AS (
    /* for each actor, the highest film count with a director other than Yash Chopra */
    SELECT adc.actor_pid,
           MAX(adc.dir_cnt) AS max_other_cnt
    FROM actor_director_counts adc
    JOIN yash_id y ON 1=1
    WHERE adc.director_pid <> y.PID
    GROUP BY adc.actor_pid
),
qualified AS (
    /* actors whose Yash Chopra count is greater than with any other director */
    SELECT ay.actor_pid
    FROM actor_yash_counts ay
    LEFT JOIN actor_other_max ao ON ay.actor_pid = ao.actor_pid
    WHERE ay.yash_cnt > IFNULL(ao.max_other_cnt, 0)
)
SELECT COUNT(*) AS actors_more_with_yash
FROM qualified;
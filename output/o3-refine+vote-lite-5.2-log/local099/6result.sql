WITH yash AS (
    SELECT PID AS yash_pid
    FROM Person
    WHERE TRIM(Name) = 'Yash Chopra'
    LIMIT 1
),
yash_films AS (
    SELECT DISTINCT MD.MID
    FROM M_Director MD, yash
    WHERE MD.PID = yash.yash_pid
),
actor_yash_counts AS (
    /* how many times each actor worked with Yash Chopra */
    SELECT MC.PID  AS actor_pid,
           COUNT(*) AS yash_count
    FROM   M_Cast      MC
    JOIN   yash_films  YF ON MC.MID = YF.MID
    GROUP BY MC.PID
),
actor_other_counts AS (
    /* collaborations between actors and every other director */
    SELECT MC.PID AS actor_pid,
           MD.PID AS director_pid,
           COUNT(*) AS cnt
    FROM   M_Cast     MC
    JOIN   M_Director MD ON MC.MID = MD.MID
    JOIN   yash       y  ON 1=1
    WHERE  MD.PID <> y.yash_pid          -- exclude Yash Chopra
    GROUP BY MC.PID, MD.PID
),
actor_max_other AS (
    /* maximum collaboration count an actor has with any non‑Yash director */
    SELECT actor_pid,
           MAX(cnt) AS max_other_cnt
    FROM   actor_other_counts
    GROUP BY actor_pid
)
SELECT COUNT(*) AS actors_more_with_yash
FROM   actor_yash_counts  a
LEFT   JOIN actor_max_other m ON a.actor_pid = m.actor_pid
WHERE  a.yash_count > IFNULL(m.max_other_cnt, 0);
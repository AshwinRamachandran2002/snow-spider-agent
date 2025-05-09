WITH nxt_matches AS (
    SELECT
        m.id,
        CAST(m.winner_id AS INTEGER) AS win_id,
        CAST(m.loser_id  AS INTEGER) AS lose_id,
        /* turn duration into total seconds so we can sort */
        CASE
            /* mm:ss (e.g. 04:02) */
            WHEN length(m.duration)=5  THEN
                 CAST(substr(m.duration,1,2) AS INTEGER)*60 +
                 CAST(substr(m.duration,4,2) AS INTEGER)
            /* h:mm:ss (e.g. 1:02:30) */
            WHEN length(m.duration)=7  THEN
                 CAST(substr(m.duration,1,1) AS INTEGER)*3600 +
                 CAST(substr(m.duration,3,2) AS INTEGER)*60 +
                 CAST(substr(m.duration,6,2) AS INTEGER)
            /* hh:mm:ss (e.g. 01:02:30) */
            WHEN length(m.duration)=8  THEN
                 CAST(substr(m.duration,1,2) AS INTEGER)*3600 +
                 CAST(substr(m.duration,4,2) AS INTEGER)*60 +
                 CAST(substr(m.duration,7,2) AS INTEGER)
        END AS secs
    FROM Matches m
    JOIN Belts   b ON b.id = m.title_id
    WHERE b.name LIKE '%NXT%'          -- only NXT‑related titles
      AND m.title_change = 0           -- exclude title‑change bouts
      AND m.duration <> ''             -- need a time to pick “shortest”
),
shortest AS (
    SELECT *
    FROM   nxt_matches
    ORDER BY secs
    LIMIT 1
)
SELECT w1.name AS wrestler_1,
       w2.name AS wrestler_2
FROM   shortest s
JOIN   Wrestlers w1 ON w1.id = s.win_id
JOIN   Wrestlers w2 ON w2.id = s.lose_id;
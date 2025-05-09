WITH nxt_matches AS (
    SELECT
        m.id,
        CAST(winner_id AS INTEGER)         AS winner_id,
        CAST(loser_id  AS INTEGER)         AS loser_id,
        -- convert the MM:SS (or H:MM:SS) string into total seconds
        CASE
            WHEN (LENGTH(m.duration) - LENGTH(REPLACE(m.duration, ':', ''))) = 2
            THEN  /* format  H:MM:SS   */
                 (CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER) * 3600)               + 
                 (CAST(substr(
                         m.duration,
                         instr(m.duration,':')+1,
                         instr(substr(m.duration,instr(m.duration,':')+1),':')-1) AS INTEGER) * 60)   + 
                 CAST(substr(m.duration,-2) AS INTEGER)
            ELSE /* format  MM:SS  */
                 (CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER) * 60) +
                 CAST(substr(m.duration,instr(m.duration,':')+1) AS INTEGER)
        END AS total_seconds
    FROM Matches m
    JOIN Belts   b ON b.id = m.title_id
    WHERE b.name LIKE '%NXT%'          -- any NXT‑related championship
      AND m.title_change = 0           -- exclude title changes
      AND m.duration <> ''             -- keep matches with a known duration
)
SELECT
    w1.name AS wrestler_1,
    w2.name AS wrestler_2
FROM nxt_matches nm
JOIN Wrestlers w1 ON w1.id = nm.winner_id
JOIN Wrestlers w2 ON w2.id = nm.loser_id
ORDER BY nm.total_seconds
LIMIT 1;
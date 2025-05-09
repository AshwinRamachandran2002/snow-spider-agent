WITH nxt_matches AS (
    SELECT
        m.id,
        m.winner_id,
        m.loser_id,
        m.duration,
        CASE                                   -- convert duration to seconds
            WHEN m.duration LIKE '%:%:%' THEN  -- HH:MM:SS
                   CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER)*3600 +
                   CAST(substr(
                            m.duration,
                            instr(m.duration,':')+1,
                            instr(substr(m.duration,instr(m.duration,':')+1),':')-1
                       ) AS INTEGER)*60 +
                   CAST(substr(m.duration,-2) AS INTEGER)
            WHEN m.duration LIKE '%:%' THEN    -- MM:SS
                   CAST(substr(m.duration,1,instr(m.duration,':')-1) AS INTEGER)*60 +
                   CAST(substr(m.duration,instr(m.duration,':')+1) AS INTEGER)
            ELSE NULL
        END AS duration_sec
    FROM Matches  m
    JOIN Belts    b ON b.id = m.title_id
    WHERE b.name LIKE '%NXT%'                 -- only NXT titles
      AND COALESCE(m.title_change,0) = 0      -- exclude title‑change matches
      AND m.duration <> ''                    -- keep matches with a duration
),
shortest AS (                               -- pick the shortest NXT title match
    SELECT *
    FROM nxt_matches
    ORDER BY duration_sec
    LIMIT 1
)
SELECT w1.name AS wrestler_1,
       w2.name AS wrestler_2
FROM shortest s
JOIN Wrestlers w1 ON w1.id = s.winner_id
JOIN Wrestlers w2 ON w2.id = s.loser_id;
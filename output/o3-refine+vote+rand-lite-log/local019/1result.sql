WITH nxt_matches AS (
    SELECT
        m.id,
        w1.name  AS winner,
        w2.name  AS loser,
        /* convert duration to seconds so we can sort numerically */
        CASE
            WHEN m.duration LIKE '%:%:%'                       -- already HH:MM:SS
                 THEN strftime('%s','1970-01-01 '||m.duration)
            ELSE                                                -- only MM:SS  ➜ prepend 00:
                 strftime('%s','1970-01-01 00:'||m.duration)
        END AS seconds
    FROM Matches  m
    JOIN Belts    b  ON CAST(m.title_id AS INTEGER) = b.id      -- belt involved
    JOIN Wrestlers w1 ON CAST(m.winner_id AS INTEGER) = w1.id   -- winner
    JOIN Wrestlers w2 ON CAST(m.loser_id  AS INTEGER) = w2.id   -- loser
    WHERE b.name  LIKE '%NXT%'          -- an NXT title
      AND m.title_change = 0            -- exclude title‑change bouts
      AND m.duration <> ''              -- must have a recorded duration
)
SELECT winner, loser
FROM   nxt_matches
ORDER  BY seconds
LIMIT  1;
WITH nxt_belts AS (
    SELECT id
    FROM Belts
    WHERE name LIKE '%NXT%'            -- all belts that contain “NXT”
),
nxt_matches AS (                       -- matches for those belts, no title‑change, with a time listed
    SELECT id,
           winner_id,
           loser_id,
           duration
    FROM Matches
    WHERE title_id IN (SELECT id FROM nxt_belts)
      AND title_change = 0
      AND duration <> ''
),
durations AS (                         -- convert the duration text to total seconds
    SELECT id,
           winner_id,
           loser_id,
           CASE
               WHEN LENGTH(duration) = 5                                       -- mm:ss
                    THEN CAST(substr(duration,1,2) AS INTEGER) * 60
                       + CAST(substr(duration,4,2) AS INTEGER)
               WHEN LENGTH(duration) = 8                                       -- hh:mm:ss
                    THEN CAST(substr(duration,1,2) AS INTEGER) * 3600
                       + CAST(substr(duration,4,2) AS INTEGER) * 60
                       + CAST(substr(duration,7,2) AS INTEGER)
               ELSE 999999                                                    -- fallback (very large)
           END AS secs
    FROM nxt_matches
)
SELECT w1.name AS wrestler1, w2.name AS wrestler2
FROM durations d
JOIN Wrestlers w1 ON w1.id = d.winner_id
JOIN Wrestlers w2 ON w2.id = d.loser_id
ORDER BY d.secs ASC                       -- shortest match first
LIMIT 1;
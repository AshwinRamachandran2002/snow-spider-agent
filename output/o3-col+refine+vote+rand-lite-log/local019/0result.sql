WITH nxt_belts AS (
  SELECT id
  FROM Belts
  WHERE name LIKE '%NXT%'                       -- every NXT-related title
),
shortest AS (
  SELECT id,
         winner_id,
         loser_id
  FROM   Matches
  WHERE  title_id     IN (SELECT id FROM nxt_belts)
    AND  title_change = 0                       -- ignore title-change bouts
    AND  duration     <> ''                     -- keep only timed matches
  ORDER BY (CAST(SUBSTR(duration,1,2) AS INT)*60   -- convert mm:ss to seconds
            + CAST(SUBSTR(duration,4,2) AS INT))
  LIMIT 1                                        -- the single shortest match
)
SELECT w1.name AS winner_name,
       w2.name AS loser_name
FROM   shortest  s
JOIN   Wrestlers w1 ON w1.id = s.winner_id
JOIN   Wrestlers w2 ON w2.id = s.loser_id;
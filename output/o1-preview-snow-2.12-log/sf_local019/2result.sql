WITH NXT_Belt AS (
  SELECT "id"
  FROM WWE.WWE.BELTS
  WHERE "name" = 'NXT Championship'
),
Matches_NXT AS (
  SELECT m.*, 
         (TRY_TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) * 60 +
          TRY_TO_NUMBER(SPLIT_PART(m."duration", ':', 2))) AS duration_seconds
  FROM WWE.WWE.MATCHES m, NXT_Belt n
  WHERE m."title_id" = n."id"
    AND m."title_change" != 1
    AND m."duration" IS NOT NULL AND m."duration" != ''
    AND SPLIT_PART(m."duration", ':', 1) != ''
    AND SPLIT_PART(m."duration", ':', 2) != ''
    AND TRY_TO_NUMBER(SPLIT_PART(m."duration", ':', 1)) IS NOT NULL
    AND TRY_TO_NUMBER(SPLIT_PART(m."duration", ':', 2)) IS NOT NULL
),
Shortest_Match AS (
  SELECT *
  FROM Matches_NXT
  ORDER BY duration_seconds ASC NULLS LAST
  LIMIT 1
),
Wrestler_Names AS (
  SELECT w1."name" AS wrestler1_name, w2."name" AS wrestler2_name
  FROM Shortest_Match m
  JOIN WWE.WWE.WRESTLERS w1 ON w1."id" = TRY_TO_NUMBER(m."winner_id")
  JOIN WWE.WWE.WRESTLERS w2 ON w2."id" = TRY_TO_NUMBER(m."loser_id")
)
SELECT wrestler1_name, wrestler2_name
FROM Wrestler_Names;
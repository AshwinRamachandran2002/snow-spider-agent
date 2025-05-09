WITH durations AS (
  SELECT m."id", m."title_id", m."duration", m."winner_id", m."loser_id",
    TRY_CAST(SPLIT_PART(m."duration", ':', 1) AS INTEGER) * 60 + TRY_CAST(SPLIT_PART(m."duration", ':', 2) AS INTEGER) AS total_seconds
  FROM "WWE"."WWE"."MATCHES" m
  WHERE m."title_id" IN (
    20604, 20638, 21126, 23153, 26117, 26983, 27226,
    27970, 65878, 66292, 66893, 66894, 66896, 67321,
    67469, 67527, 67583, 67648, 67836, 70177
  )
    AND m."title_change" = 0
    AND m."duration" IS NOT NULL
    AND m."duration" <> ''
),
shortest_match AS (
  SELECT *
  FROM durations
  WHERE total_seconds IS NOT NULL
  ORDER BY total_seconds ASC
  LIMIT 1
)
SELECT w1."name" AS wrestler1_name, w2."name" AS wrestler2_name
FROM shortest_match m
JOIN "WWE"."WWE"."WRESTLERS" w1 ON m."winner_id" = w1."id"
JOIN "WWE"."WWE"."WRESTLERS" w2 ON m."loser_id" = w2."id";
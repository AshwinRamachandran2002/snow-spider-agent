SELECT
  w1."name" AS "Wrestler_1",
  w2."name" AS "Wrestler_2"
FROM "Matches" m
JOIN "Wrestlers" w1 ON w1."id" = CAST(m."winner_id" AS INTEGER)
JOIN "Wrestlers" w2 ON w2."id" = CAST(m."loser_id"  AS INTEGER)
WHERE m."id" = (
  SELECT "id"
  FROM   "Matches"
  WHERE  "title_id" IN (SELECT "id" FROM "Belts" WHERE "name" LIKE '%NXT%')
    AND  "title_change" = 0                      -- exclude title-change bouts
    AND  "duration" LIKE '%:%'                   -- keep only matches with a recorded time
  ORDER BY (CAST(substr("duration",1, instr("duration",':')-1) AS INTEGER) * 60 +
            CAST(substr("duration", instr("duration",':')+1)  AS INTEGER))
  LIMIT 1
);
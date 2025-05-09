SELECT
    w1."name" AS "Wrestler_1",
    w2."name" AS "Wrestler_2"
FROM "Matches" AS m
JOIN "Wrestlers" AS w1 ON w1."id" = CAST(m."winner_id" AS INT)
JOIN "Wrestlers" AS w2 ON w2."id" = CAST(m."loser_id" AS INT)
WHERE m."title_id" IN (
        SELECT "id"
        FROM "Belts"
        WHERE "name" LIKE '%NXT%'
      )
  AND m."title_change" = 0
  AND m."duration" <> ''
ORDER BY CAST(substr(m."duration", 1, instr(m."duration", ':') - 1) AS INT) * 60
       + CAST(substr(m."duration", instr(m."duration", ':') + 1) AS INT)
LIMIT 1;
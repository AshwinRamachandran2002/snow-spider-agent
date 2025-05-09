SELECT w1."name" AS "Winner_name", w2."name" AS "Loser_name"
FROM "Matches" m
JOIN "Wrestlers" w1 ON m."winner_id" = w1."id"
JOIN "Wrestlers" w2 ON m."loser_id" = w2."id"
WHERE m."title_id" = (SELECT "id" FROM "Belts" WHERE "name" = 'NXT Championship')
  AND m."title_change" = 0
  AND m."duration" IS NOT NULL AND m."duration" != ''
  AND LENGTH(m."duration") >= 4
  AND INSTR(m."duration", ':') > 0
ORDER BY
  ((CAST(SUBSTR(m."duration", 1, INSTR(m."duration", ':') - 1) AS INTEGER) * 60) +
  CAST(SUBSTR(m."duration", INSTR(m."duration", ':') + 1) AS INTEGER)) ASC,
  m."id" ASC
LIMIT 1;
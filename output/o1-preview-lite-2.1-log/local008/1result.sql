SELECT 'Games played' AS stat_name, p."name_given" AS player_name, t.score
FROM (
    SELECT b."player_id", SUM(b."g") AS score
    FROM "batting" b
    GROUP BY b."player_id"
) t
JOIN "player" p ON t."player_id" = p."player_id"
WHERE t.score = (SELECT MAX(total_score) FROM (SELECT SUM(b."g") AS total_score FROM "batting" b GROUP BY b."player_id"))
UNION ALL
SELECT 'Runs' AS stat_name, p."name_given" AS player_name, t.score
FROM (
    SELECT b."player_id", SUM(b."r") AS score
    FROM "batting" b
    GROUP BY b."player_id"
) t
JOIN "player" p ON t."player_id" = p."player_id"
WHERE t.score = (SELECT MAX(total_score) FROM (SELECT SUM(b."r") AS total_score FROM "batting" b GROUP BY b."player_id"))
UNION ALL
SELECT 'Hits' AS stat_name, p."name_given" AS player_name, t.score
FROM (
    SELECT b."player_id", SUM(b."h") AS score
    FROM "batting" b
    GROUP BY b."player_id"
) t
JOIN "player" p ON t."player_id" = p."player_id"
WHERE t.score = (SELECT MAX(total_score) FROM (SELECT SUM(b."h") AS total_score FROM "batting" b GROUP BY b."player_id"))
UNION ALL
SELECT 'Home runs' AS stat_name, p."name_given" AS player_name, t.score
FROM (
    SELECT b."player_id", SUM(b."hr") AS score
    FROM "batting" b
    GROUP BY b."player_id"
) t
JOIN "player" p ON t."player_id" = p."player_id"
WHERE t.score = (SELECT MAX(total_score) FROM (SELECT SUM(b."hr") AS total_score FROM "batting" b GROUP BY b."player_id"));
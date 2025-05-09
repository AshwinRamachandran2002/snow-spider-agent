SELECT 'Games played' AS stat_name, p."name_given" AS player_name, s.score
FROM (
    SELECT b."player_id", SUM(b."g") AS score
    FROM "batting" AS b
    WHERE b."g" IS NOT NULL
    GROUP BY b."player_id"
    ORDER BY score DESC
    LIMIT 1
) AS s
JOIN "player" AS p ON p."player_id" = s."player_id"
UNION ALL
SELECT 'Runs' AS stat_name, p."name_given", s.score
FROM (
    SELECT b."player_id", SUM(b."r") AS score
    FROM "batting" AS b
    WHERE b."r" IS NOT NULL
    GROUP BY b."player_id"
    ORDER BY score DESC
    LIMIT 1
) AS s
JOIN "player" AS p ON p."player_id" = s."player_id"
UNION ALL
SELECT 'Hits' AS stat_name, p."name_given", s.score
FROM (
    SELECT b."player_id", SUM(b."h") AS score
    FROM "batting" AS b
    WHERE b."h" IS NOT NULL
    GROUP BY b."player_id"
    ORDER BY score DESC
    LIMIT 1
) AS s
JOIN "player" AS p ON p."player_id" = s."player_id"
UNION ALL
SELECT 'Home runs' AS stat_name, p."name_given", s.score
FROM (
    SELECT b."player_id", SUM(b."hr") AS score
    FROM "batting" AS b
    WHERE b."hr" IS NOT NULL
    GROUP BY b."player_id"
    ORDER BY score DESC
    LIMIT 1
) AS s
JOIN "player" AS p ON p."player_id" = s."player_id";
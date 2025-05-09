WITH first_gold_badge_per_user AS (          -- every gold badge a user ever earned
    SELECT
        b."user_id",
        b."name"          AS "badge_name",
        b."date"          AS "badge_date",
        ROW_NUMBER() OVER (PARTITION BY b."user_id" ORDER BY b."date") AS "rn"
    FROM STACKOVERFLOW.STACKOVERFLOW."BADGES" b
    WHERE b."class" = 1                       -- 1 = gold
),
first_gold AS (                               -- keep only the first gold badge per user
    SELECT
        fg."user_id",
        fg."badge_name",
        fg."badge_date"
    FROM first_gold_badge_per_user fg
    WHERE fg."rn" = 1
),
with_age AS (                                 -- days from account‑creation to first‑gold
    SELECT
        fg."badge_name",
        (fg."badge_date" - u."creation_date") / 86400000000.0 AS "days_to_badge"
    FROM first_gold fg
    JOIN STACKOVERFLOW.STACKOVERFLOW."USERS" u
          ON fg."user_id" = u."id"
)
SELECT
    w."badge_name",
    COUNT(*)                       AS "users_first_gold",
    AVG(w."days_to_badge")         AS "avg_days_to_first_gold_badge"
FROM with_age w
GROUP BY w."badge_name"
ORDER BY "users_first_gold" DESC, w."badge_name"
LIMIT 10;
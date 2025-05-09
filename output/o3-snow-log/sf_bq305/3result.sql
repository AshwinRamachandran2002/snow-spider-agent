WITH
/* -------- two base tables -------- */
q AS (                                      -- questions
    SELECT
        "id",
        "owner_user_id",
        "view_count",
        "accepted_answer_id"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
),
a AS (                                      -- answers
    SELECT
        "id",
        "parent_id",        -- question id
        "owner_user_id",
        "score"
    FROM STACKOVERFLOW.STACKOVERFLOW.POSTS_ANSWERS
),

/* -------- association rules -------- */
q_owner AS (                                -- rule 1
    SELECT
        "owner_user_id" AS user_id,
        "id"            AS question_id
    FROM q
    WHERE "owner_user_id" IS NOT NULL
),

accepted AS (                               -- rule 2
    SELECT
        a."owner_user_id" AS user_id,
        q."id"            AS question_id
    FROM q
    JOIN a
      ON a."id" = q."accepted_answer_id"
    WHERE a."owner_user_id" IS NOT NULL
),

high_score AS (                             -- rule 3
    SELECT
        "owner_user_id" AS user_id,
        "parent_id"     AS question_id
    FROM a
    WHERE "score" > 5
      AND "owner_user_id" IS NOT NULL
),

top_three AS (                              -- rule 4
    SELECT
        "owner_user_id" AS user_id,
        "parent_id"     AS question_id
    FROM (
        SELECT
            "owner_user_id",
            "parent_id",
            ROW_NUMBER() OVER (PARTITION BY "parent_id" ORDER BY "score" DESC) AS rn
        FROM a
        WHERE "owner_user_id" IS NOT NULL
    )
    WHERE rn <= 3
),

rel_score AS (                              -- rule 5
    WITH tot AS (
        SELECT
            "parent_id"      AS question_id,
            SUM("score")     AS total_score
        FROM a
        GROUP BY "parent_id"
    )
    SELECT
        a."owner_user_id" AS user_id,
        a."parent_id"     AS question_id
    FROM a
    JOIN tot
      ON tot.question_id = a."parent_id"
    WHERE a."score" > 0
      AND a."score" >= 0.20 * tot.total_score
      AND a."owner_user_id" IS NOT NULL
),

/* -------- merge all associations -------- */
assoc AS (
    SELECT DISTINCT user_id, question_id FROM (
        SELECT * FROM q_owner
        UNION
        SELECT * FROM accepted
        UNION
        SELECT * FROM high_score
        UNION
        SELECT * FROM top_three
        UNION
        SELECT * FROM rel_score
    )
),

/* -------- sum view counts per user -------- */
user_views AS (
    SELECT
        assoc.user_id,
        SUM(q."view_count") AS combined_views
    FROM assoc
    JOIN q
      ON q."id" = assoc.question_id
    GROUP BY assoc.user_id
)

/* -------- final result -------- */
SELECT
    u."display_name",
    uv.user_id,
    uv.combined_views
FROM user_views uv
JOIN STACKOVERFLOW.STACKOVERFLOW.USERS u
  ON u."id" = uv.user_id
ORDER BY uv.combined_views DESC NULLS LAST
LIMIT 10;
WITH
    total_answer_scores AS (
        SELECT
            a."parent_id" AS "question_id",
            SUM(a."score") AS "total_score"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        GROUP BY
            a."parent_id"
    ),
    criterion4 AS (
        SELECT
            a."owner_user_id" AS "user_id",
            a."parent_id" AS "question_id"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
            JOIN total_answer_scores tas ON a."parent_id" = tas."question_id"
        WHERE
            a."score" > 0
            AND tas."total_score" > 0
            AND (a."score" / tas."total_score") > 0.2
            AND a."owner_user_id" IS NOT NULL
    ),
    criterion5 AS (
        SELECT
            ra."user_id",
            ra."question_id"
        FROM (
            SELECT
                a."owner_user_id" AS "user_id",
                a."parent_id" AS "question_id",
                a."score",
                ROW_NUMBER() OVER (PARTITION BY a."parent_id" ORDER BY a."score" DESC) AS "rank"
            FROM
                STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
            WHERE
                a."owner_user_id" IS NOT NULL
        ) ra
        WHERE
            ra."rank" <= 3
        ),
    associations AS (
        SELECT
            q."owner_user_id" AS "user_id",
            q."id" AS "question_id"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q
        WHERE
            q."owner_user_id" IS NOT NULL
        UNION
        SELECT
            a."owner_user_id" AS "user_id",
            q."id" AS "question_id"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
            JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q ON q."accepted_answer_id" = a."id"
        WHERE
            a."owner_user_id" IS NOT NULL
        UNION
        SELECT
            a."owner_user_id" AS "user_id",
            a."parent_id" AS "question_id"
        FROM
            STACKOVERFLOW.STACKOVERFLOW."POSTS_ANSWERS" a
        WHERE
            a."score" > 5
            AND a."owner_user_id" IS NOT NULL
        UNION
        SELECT
            c4."user_id",
            c4."question_id"
        FROM
            criterion4 c4
        UNION
        SELECT
            c5."user_id",
            c5."question_id"
        FROM
            criterion5 c5
    ),
    distinct_associations AS (
        SELECT DISTINCT
            "user_id",
            "question_id"
        FROM
            associations
    ),
    user_view_counts AS (
        SELECT
            da."user_id",
            SUM(q."view_count") AS "Combined_View_Count"
        FROM
            distinct_associations da
            JOIN STACKOVERFLOW.STACKOVERFLOW."POSTS_QUESTIONS" q ON da."question_id" = q."id"
        GROUP BY
            da."user_id"
    )
SELECT
    uv."user_id" AS "User_ID",
    uv."Combined_View_Count"
FROM
    user_view_counts uv
ORDER BY
    uv."Combined_View_Count" DESC NULLS LAST
LIMIT 10;
WITH user_posts_with_tags AS (
    -- Get the user's questions
    SELECT
        P."id",
        P."tags",
        0 AS "is_accepted_answer"
    FROM STACKOVERFLOW.STACKOVERFLOW.STACKOVERFLOW_POSTS P
    WHERE
        P."owner_user_id" = 1908967
        AND P."creation_date" < 1528329600000000  -- June 7, 2018 in microseconds since epoch
        AND P."post_type_id" = 1  -- Questions
    UNION ALL
    -- Get the user's answers and check if they are accepted
    SELECT
        A."id",
        Q."tags",
        CASE WHEN Q."accepted_answer_id" = A."id" THEN 1 ELSE 0 END AS "is_accepted_answer"
    FROM STACKOVERFLOW.STACKOVERFLOW.STACKOVERFLOW_POSTS A
    JOIN STACKOVERFLOW.STACKOVERFLOW.STACKOVERFLOW_POSTS Q
        ON A."parent_id" = Q."id"
    WHERE
        A."owner_user_id" = 1908967
        AND A."creation_date" < 1528329600000000  -- June 7, 2018 in microseconds since epoch
        AND A."post_type_id" = 2  -- Answers
),
post_upvotes AS (
    -- Count upvotes for each post
    SELECT
        V."post_id",
        COUNT(*) AS "upvotes"
    FROM STACKOVERFLOW.STACKOVERFLOW.VOTES V
    WHERE
        V."vote_type_id" = 2  -- Upvotes
        AND V."creation_date" < 1528329600000000  -- June 7, 2018 in microseconds since epoch
    GROUP BY V."post_id"
),
post_tags AS (
    -- Unnest tags for each post
    SELECT
        U."id",
        U."is_accepted_answer",
        COALESCE(PU."upvotes", 0) AS "upvotes",
        TRIM(tag.value::string) AS "tag"
    FROM user_posts_with_tags U
    LEFT JOIN post_upvotes PU ON U."id" = PU."post_id",
    LATERAL FLATTEN(input => SPLIT(U."tags", '|')) AS tag
)
-- Calculate the total score per tag
SELECT
    pt."tag" AS "Tag",
    (10 * SUM(pt."upvotes") + 15 * SUM(pt."is_accepted_answer")) AS "Total_Score"
FROM post_tags pt
GROUP BY pt."tag"
ORDER BY "Total_Score" DESC NULLS LAST
LIMIT 10;
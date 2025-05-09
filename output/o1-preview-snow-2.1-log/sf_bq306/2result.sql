SELECT
    LOWER(TRIM(tag.value::STRING)) AS "Tag",
    SUM(p."upvote_count") * 10 + SUM(p."accepted_answer") * 15 AS "Total_Score"
FROM (
    -- Questions by the user before June 7, 2018
    SELECT
        q."id" AS "post_id",
        q."tags",
        0 AS "accepted_answer",
        COUNT(DISTINCT v."id") AS "upvote_count"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS q
    LEFT JOIN "STACKOVERFLOW"."STACKOVERFLOW"."VOTES" AS v
        ON v."post_id" = q."id"
        AND v."vote_type_id" = 2  -- Upvotes
        AND v."creation_date" < 1528329600000000  -- Before June 7, 2018
    WHERE q."owner_user_id" = 1908967
        AND q."creation_date" < 1528329600000000  -- Before June 7, 2018
    GROUP BY q."id", q."tags"

    UNION ALL

    -- Answers by the user before June 7, 2018
    SELECT
        a."id" AS "post_id",
        q."tags",
        CASE WHEN q."accepted_answer_id" = a."id" THEN 1 ELSE 0 END AS "accepted_answer",
        COUNT(DISTINCT v."id") AS "upvote_count"
    FROM "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_ANSWERS" AS a
    JOIN "STACKOVERFLOW"."STACKOVERFLOW"."POSTS_QUESTIONS" AS q
        ON a."parent_id" = q."id"
    LEFT JOIN "STACKOVERFLOW"."STACKOVERFLOW"."VOTES" AS v
        ON v."post_id" = a."id"
        AND v."vote_type_id" = 2  -- Upvotes
        AND v."creation_date" < 1528329600000000  -- Before June 7, 2018
    WHERE a."owner_user_id" = 1908967
        AND a."creation_date" < 1528329600000000  -- Before June 7, 2018
    GROUP BY a."id", q."tags", q."accepted_answer_id"
) AS p,
LATERAL FLATTEN(
    INPUT => SPLIT(REGEXP_REPLACE(p."tags", '^<|>$', ''), '><')
) AS tag
WHERE tag.value IS NOT NULL AND tag.value != ''
GROUP BY LOWER(TRIM(tag.value::STRING))
ORDER BY "Total_Score" DESC NULLS LAST
LIMIT 10;
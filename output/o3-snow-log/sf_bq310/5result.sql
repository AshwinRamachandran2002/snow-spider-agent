SELECT
    "title"
FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE
    LOWER("title") LIKE 'how %'                   -- “how” questions
    AND (
        LOWER("tags") LIKE '%android-%'           -- any tag that starts with android-
        OR LOWER("tags") LIKE '%|android|%'       -- plain “android” tag (if present)
    )
ORDER BY
    "view_count" DESC NULLS LAST                  -- most-viewed first
LIMIT 1;
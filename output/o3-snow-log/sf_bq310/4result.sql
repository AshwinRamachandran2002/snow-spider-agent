SELECT
    "title"
FROM
    STACKOVERFLOW.STACKOVERFLOW.POSTS_QUESTIONS
WHERE
    LOWER("title") LIKE '%how%'                             -- “how” questions
    AND (
           "tags" LIKE '%android-layout%'                   -- Android-related tags
        OR "tags" LIKE '%android-activity%'
        OR "tags" LIKE '%android-intent%'
        OR "tags" LIKE '%android%'                          -- any other Android tag
    )
ORDER BY
    "view_count" DESC NULLS LAST
LIMIT 1;
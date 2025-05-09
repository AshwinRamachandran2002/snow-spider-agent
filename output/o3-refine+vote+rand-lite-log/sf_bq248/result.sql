WITH python_repos AS (               /* repos that mention a python language */
    SELECT DISTINCT "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(CAST("language" AS STRING)) LIKE '%python%'
),
candidate_files AS (                 /* files that belong to non‑python repos */
    SELECT  f."repo_name",
            f."id",
            f."path"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
    LEFT JOIN python_repos  p
           ON f."repo_name" = p."repo_name"
    WHERE   p."repo_name" IS NULL
),
files_with_content AS (              /* attach file contents (may be NULL) */
    SELECT  cf."path",
            c."content"
    FROM    candidate_files            AS cf
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
           ON cf."id" = c."id"
)
SELECT
    COUNT_IF(
        LOWER("path")    LIKE '%readme.md%'   -- path contains readme.md
        AND
        LOWER("content") LIKE '%copyright (c)%'   -- content has phrase
    ) :: FLOAT
    /
    COUNT(*)                                   -- all files in non‑python repos
    AS "proportion"
FROM files_with_content;
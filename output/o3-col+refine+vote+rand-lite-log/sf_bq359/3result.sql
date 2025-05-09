WITH lang_ranked AS (
    SELECT
        l."repo_name",
        f.value:"name"::STRING  AS "language_name",
        f.value:"bytes"::NUMBER AS "bytes",
        DENSE_RANK() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::NUMBER DESC
        ) AS "lang_rank"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES AS l,
         LATERAL FLATTEN(input => l."language") AS f
),
js_primary_repos AS (
    SELECT
        "repo_name"
    FROM lang_ranked
    WHERE "lang_rank" = 1
      AND "language_name" ILIKE 'javascript'
)
SELECT
    c."repo_name",
    COUNT(*) AS "commit_cnt"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
JOIN js_primary_repos AS j
  ON c."repo_name" = j."repo_name"
GROUP BY c."repo_name"
ORDER BY "commit_cnt" DESC NULLS LAST
LIMIT 2;
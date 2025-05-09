WITH lang_rank AS (
    SELECT
        l."repo_name",
        f.value:"name"::string     AS "language",
        f.value:"bytes"::number    AS "bytes",
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY f.value:"bytes"::number DESC
        ) AS rn
    FROM
        GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
        LATERAL FLATTEN(INPUT => l."language") f
    WHERE
        f.value:"name" IS NOT NULL       -- ignore empty language arrays
)
SELECT
    c."repo_name",
    COUNT(*) AS "commit_count"
FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN
    (SELECT "repo_name", "language"
       FROM lang_rank
       WHERE rn = 1) p
      ON c."repo_name" = p."repo_name"
WHERE
    p."language" = 'JavaScript'
GROUP BY
    c."repo_name"
ORDER BY
    "commit_count" DESC NULLS LAST
FETCH 2;
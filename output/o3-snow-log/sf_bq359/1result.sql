SELECT
    l."repo_name",
    COUNT(c."commit") AS "commit_count"
FROM
    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES      AS l
JOIN
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS AS c
      ON l."repo_name" = c."repo_name"
WHERE
    LOWER(l."language"::STRING) LIKE '%javascript%'      -- repositories whose primary language is JavaScript
GROUP BY
    l."repo_name"
ORDER BY
    "commit_count" DESC NULLS LAST
LIMIT 2;
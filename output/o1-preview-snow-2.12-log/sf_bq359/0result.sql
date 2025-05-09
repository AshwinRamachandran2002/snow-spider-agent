WITH primary_language_js AS (
    SELECT
        pl."repo_name"
    FROM (
        SELECT
            t."repo_name",
            f.value:"bytes"::INT AS "bytes",
            f.value:"name"::STRING AS "language_name",
            ROW_NUMBER() OVER (PARTITION BY t."repo_name" ORDER BY f.value:"bytes"::INT DESC) AS rn
        FROM GITHUB_REPOS.GITHUB_REPOS."LANGUAGES" t,
        LATERAL FLATTEN(input => t."language") f
    ) pl
    WHERE pl.rn = 1 AND pl."language_name" = 'JavaScript'
)
SELECT
    sc."repo_name" AS "repository_name",
    COUNT(sc."commit") AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_COMMITS" sc
JOIN primary_language_js pl
    ON sc."repo_name" = pl."repo_name"
GROUP BY sc."repo_name"
ORDER BY "commit_count" DESC NULLS LAST
LIMIT 2;
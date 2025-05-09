SELECT
     COUNT(*) / 12.0 AS "Average_Commits_per_Month"
FROM
     GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
INNER JOIN
    (
        SELECT DISTINCT t."repo_name"
        FROM
            GITHUB_REPOS.GITHUB_REPOS.LANGUAGES t,
            LATERAL FLATTEN(input => t."language") f
        WHERE
            f.value:"name"::STRING = 'Python'
    ) p
ON c."repo_name" = p."repo_name"
WHERE
    YEAR(TO_TIMESTAMP_NTZ(c."author":"date"::NUMBER / 1000000)) = 2016;
WITH
    /* 1 ── repos with an acceptable OSS licence */
    "licenced_repos" AS (
        SELECT DISTINCT "repo_name"
        FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES
        WHERE "license" IN ('artistic-2.0','isc','mit','apache-2.0')
    ),

    /* 2 ── repos that contain at least one *.py file on the master branch */
    "python_repos" AS (
        SELECT DISTINCT "repo_name"
        FROM GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_FILES
        WHERE "path" ILIKE '%.py'
          AND "ref"  = 'refs/heads/master'
    ),

    /* 3 ── watcher counts (snapshot) */
    "watchers" AS (
        SELECT "repo_name", "watch_count"
        FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.SAMPLE_REPOS
    ),

    /* 4 ── issue-related events in April-2022 */
    "issues_apr22" AS (
        SELECT
            "repo":"name"::STRING  AS "repo_name",
            COUNT(*)               AS "issues_cnt"
        FROM GITHUB_REPOS_DATE.YEAR."_2022"
        WHERE "type" ILIKE '%Issue%'
          AND "created_at" BETWEEN 1648771200000000 AND 1651363199000000
        GROUP BY 1
    ),

    /* 5 ── fork events in the same period */
    "forks_apr22" AS (
        SELECT
            "repo":"name"::STRING  AS "repo_name",
            COUNT(*)               AS "forks_cnt"
        FROM GITHUB_REPOS_DATE.YEAR."_2022"
        WHERE "type" = 'ForkEvent'
          AND "created_at" BETWEEN 1648771200000000 AND 1651363199000000
        GROUP BY 1
    ),

    /* 6 ── aggregate activity metric */
    "activity" AS (
        SELECT
            w."repo_name",
            COALESCE(w."watch_count",0) +
            COALESCE(i."issues_cnt",0)  +
            COALESCE(f."forks_cnt",0)   AS "activity_score"
        FROM "watchers" w
        LEFT JOIN "issues_apr22" i ON w."repo_name" = i."repo_name"
        LEFT JOIN "forks_apr22"  f ON w."repo_name" = f."repo_name"
    )

/* 7 ── most-active Python repo in April-2022 */
SELECT
    a."repo_name",
    a."activity_score"
FROM "activity"       a
JOIN "licenced_repos" l ON a."repo_name" = l."repo_name"
JOIN "python_repos"   p ON a."repo_name" = p."repo_name"
ORDER BY a."activity_score" DESC NULLS LAST
LIMIT 1;
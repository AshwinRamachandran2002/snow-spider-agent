/* ----------------------------------------------------------------------
   Count PullRequestEvents that occurred on 18-Jan-2023, grouped by each
   repository’s primary language (largest byte count).  Repositories that
   have no language record are counted under 'UNKNOWN'.  Return languages
   that accumulated at least 100 such events.
   ---------------------------------------------------------------------*/
WITH primary_language AS (
    /* Choose the dominant language (highest byte count) per repository */
    SELECT
        l."repo_name",
        f.value:"name"::STRING                          AS "language",
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY (f.value:"bytes")::NUMBER DESC NULLS LAST
        )                                               AS rn
    FROM GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language", outer => TRUE) f
),
repos_main_lang AS (
    /* Keep only one row per repo */
    SELECT
        "repo_name",
        COALESCE("language", 'UNKNOWN') AS "language"
    FROM primary_language
    WHERE rn = 1
),
pull_requests_2023_01_18 AS (
    /* All PullRequestEvents on 2023-01-18 */
    SELECT
        t."repo":"name"::STRING AS "repo_name"
    FROM GITHUB_REPOS_DATE.YEAR."_2023" t
    WHERE t."type" = 'PullRequestEvent'
      AND TO_DATE(TO_TIMESTAMP(t."created_at" / 1000000)) = '2023-01-18'
)
SELECT
    COALESCE(rml."language", 'UNKNOWN') AS "language",
    COUNT(*)                            AS "pull_request_events"
FROM pull_requests_2023_01_18  pr
LEFT JOIN repos_main_lang       rml
       ON pr."repo_name" = rml."repo_name"
GROUP BY COALESCE(rml."language", 'UNKNOWN')
HAVING COUNT(*) >= 100
ORDER BY "pull_request_events" DESC NULLS LAST;
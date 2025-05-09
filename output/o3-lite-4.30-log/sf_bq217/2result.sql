SELECT
    '2023-01-18' AS event_date,
    COUNT(*)     AS pull_request_creation_events
FROM (
    /* pull‑request creation events on 18‑Jan‑2023 */
    SELECT
        TRY_PARSE_JSON("repo"):name::STRING AS repo_name
    FROM GITHUB_REPOS_DATE.YEAR."_2023"
    WHERE "type" = 'PullRequestEvent'
      AND TRY_PARSE_JSON("payload"):action::STRING = 'opened'
      AND TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) = '2023-01-18'
) pr
JOIN (
    /* repositories that include JavaScript among their languages */
    SELECT DISTINCT
           l."repo_name"
    FROM   GITHUB_REPOS_DATE.GITHUB_REPOS.LANGUAGES l,
           LATERAL FLATTEN(input => l."language") f
    WHERE  LOWER(f.value::STRING) = 'javascript'
) js
ON pr.repo_name = js."repo_name";
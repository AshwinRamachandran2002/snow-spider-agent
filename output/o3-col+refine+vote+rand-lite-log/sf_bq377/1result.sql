SELECT
    f.KEY        AS "package_name",
    COUNT(*)     AS "freq"
FROM (
    SELECT TRY_PARSE_JSON("content") AS j
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "sample_path" ILIKE '%composer.json%'
) t,
LATERAL FLATTEN(INPUT => t.j:"require") f
GROUP BY f.KEY
ORDER BY "freq" DESC NULLS LAST;
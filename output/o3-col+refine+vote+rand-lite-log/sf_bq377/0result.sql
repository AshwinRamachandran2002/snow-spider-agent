SELECT
    r.key            AS "package_name",
    COUNT(*)         AS "frequency"
FROM
    GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS",
    LATERAL FLATTEN(
        INPUT => GET(PARSE_JSON("content"), 'require')
    ) r
WHERE
    "sample_path" ILIKE '%composer.json%'
GROUP BY
    r.key
ORDER BY
    "frequency" DESC NULLS LAST;
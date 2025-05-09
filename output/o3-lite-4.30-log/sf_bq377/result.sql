SELECT
    f.key AS "package_name",
    COUNT(*) AS "frequency"
FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
    LATERAL FLATTEN(input => PARSE_JSON(t."content"):require) f
WHERE
    t."sample_path" ILIKE '%composer.json%'
GROUP BY
    f.key
ORDER BY
    "frequency" DESC NULLS LAST,
    "package_name" ASC;
SELECT
    CASE
        WHEN REGEXP_LIKE("content", '.*[ \t]$', 'm') THEN 'Trailing'
        WHEN REGEXP_LIKE("content", '^ .*', 'm') THEN 'Space'
        ELSE 'Other'
    END AS "Category",
    COUNT(*) AS "Number_of_Files"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
WHERE "binary" = FALSE
GROUP BY "Category";
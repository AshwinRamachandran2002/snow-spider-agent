WITH parsed AS (
    SELECT 
        OBJECT_KEYS(TRY_PARSE_JSON("content"):"require") AS req_array
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE TRY_PARSE_JSON("content"):"require" IS NOT NULL
)
SELECT 
    f.value::string AS "package_name",
    COUNT(*)        AS "frequency"
FROM parsed,
     LATERAL FLATTEN(input => req_array) f
GROUP BY "package_name"
ORDER BY "frequency" DESC NULLS LAST,
         "package_name";
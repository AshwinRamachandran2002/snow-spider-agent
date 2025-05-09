/* Non-empty, non-comment README lines,
   their cross-repo frequency, and languages used */
SELECT
    ln."clean_line",
    COUNT(DISTINCT ln."repo_name")                                            AS "repo_frequency",
    LISTAGG(DISTINCT lg."lang_name", ',') 
        WITHIN GROUP (ORDER BY lg."lang_name")                                AS "languages_used"
FROM (
        /* distinct <repo , line> pairs coming from README.md files */
        SELECT DISTINCT
               c."sample_repo_name"                       AS "repo_name",
               TRIM(spl.value)::STRING                    AS "clean_line"
        FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
             LATERAL SPLIT_TO_TABLE(c."content", '\n') spl
        WHERE c."sample_path" ILIKE '%README.md%'
          AND TRIM(spl.value) <> ''                       -- drop blank lines
          AND NOT TRIM(spl.value) ILIKE '#%'              -- drop markdown headers
          AND NOT TRIM(spl.value) ILIKE '//%'             -- drop // comments
) ln
LEFT JOIN (
        /* explode language arrays to one row per language name */
        SELECT
            l."repo_name",
            fl.value:"name"::STRING           AS "lang_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
             LATERAL FLATTEN(input => l."language") fl
) lg
       ON lg."repo_name" = ln."repo_name"
GROUP BY ln."clean_line"
ORDER BY "repo_frequency" DESC NULLS LAST;
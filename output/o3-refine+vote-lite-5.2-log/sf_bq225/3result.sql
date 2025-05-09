/* Top‑10 languages by number of text files with non‑empty content */
SELECT
    language,
    COUNT(*) AS file_count
FROM (
    SELECT
        CASE
            WHEN REGEXP_LIKE(path_low, '\\.(asm|nasm)$')                                   THEN 'Assembly'
            WHEN REGEXP_LIKE(path_low, '\\.c$')                                           THEN 'C'
            WHEN REGEXP_LIKE(path_low, '\\.cs$')                                          THEN 'C#'
            WHEN REGEXP_LIKE(path_low, '\\.(c\\+\\+|cpp|h\\+\\+|hpp)$')                   THEN 'C++'
            WHEN REGEXP_LIKE(path_low, '\\.css$')                                         THEN 'CSS'
            WHEN REGEXP_LIKE(path_low, '\\.clj$')                                         THEN 'Clojure'
            WHEN REGEXP_LIKE(path_low, '\\.lisp$')                                        THEN 'Common Lisp'
            WHEN REGEXP_LIKE(path_low, '\\.d$')                                           THEN 'D'
            WHEN REGEXP_LIKE(path_low, '\\.dart$')                                        THEN 'Dart'
            WHEN REGEXP_LIKE(path_low, '(^|/)dockerfile$|\\.dockerfile$')                 THEN 'Dockerfile'
            WHEN REGEXP_LIKE(path_low, '\\.(ex|exs)$')                                    THEN 'Elixir'
            WHEN REGEXP_LIKE(path_low, '\\.erl$')                                         THEN 'Erlang'
            WHEN REGEXP_LIKE(path_low, '\\.go$')                                          THEN 'Go'
            WHEN REGEXP_LIKE(path_low, '\\.groovy$')                                      THEN 'Groovy'
            WHEN REGEXP_LIKE(path_low, '\\.(html?|htm)$')                                 THEN 'HTML'
            WHEN REGEXP_LIKE(path_low, '\\.hs$')                                          THEN 'Haskell'
            WHEN REGEXP_LIKE(path_low, '\\.hx$')                                          THEN 'Haxe'
            WHEN REGEXP_LIKE(path_low, '\\.json$')                                        THEN 'JSON'
            WHEN REGEXP_LIKE(path_low, '\\.java$')                                        THEN 'Java'
            WHEN REGEXP_LIKE(path_low, '\\.(js|cjs)$')                                    THEN 'JavaScript'
            WHEN REGEXP_LIKE(path_low, '\\.jl$')                                          THEN 'Julia'
            WHEN REGEXP_LIKE(path_low, '\\.(kt|ktm|kts)$')                                THEN 'Kotlin'
            WHEN REGEXP_LIKE(path_low, '\\.lua$')                                         THEN 'Lua'
            WHEN REGEXP_LIKE(path_low, '\\.(matlab|m)$')                                  THEN 'MATLAB'
            WHEN REGEXP_LIKE(path_low, '\\.(md|markdown|mdown)$')                         THEN 'Markdown'
            WHEN REGEXP_LIKE(path_low, '\\.php$')                                         THEN 'PHP'
            WHEN REGEXP_LIKE(path_low, '\\.(ps1|psd1|psm1)$')                             THEN 'PowerShell'
            WHEN REGEXP_LIKE(path_low, '\\.py$')                                          THEN 'Python'
            WHEN REGEXP_LIKE(path_low, '\\.r$')                                           THEN 'R'
            WHEN REGEXP_LIKE(path_low, '\\.rb$')                                          THEN 'Ruby'
            WHEN REGEXP_LIKE(path_low, '\\.rs$')                                          THEN 'Rust'
            WHEN REGEXP_LIKE(path_low, '\\.scss$')                                        THEN 'SCSS'
            WHEN REGEXP_LIKE(path_low, '\\.sql$')                                         THEN 'SQL'
            WHEN REGEXP_LIKE(path_low, '\\.sass$')                                        THEN 'Sass'
            WHEN REGEXP_LIKE(path_low, '\\.scala$')                                       THEN 'Scala'
            WHEN REGEXP_LIKE(path_low, '\\.(sh|bash)$')                                   THEN 'Shell'
            WHEN REGEXP_LIKE(path_low, '\\.swift$')                                       THEN 'Swift'
            WHEN REGEXP_LIKE(path_low, '\\.ts$')                                          THEN 'TypeScript'
            WHEN REGEXP_LIKE(path_low, '\\.vue$')                                         THEN 'Vue'
            WHEN REGEXP_LIKE(path_low, '\\.xml$')                                         THEN 'XML'
            WHEN REGEXP_LIKE(path_low, '\\.(yml|yaml)$')                                  THEN 'YAML'
        END AS language
    FROM (
        SELECT LOWER("sample_path") AS path_low
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
        WHERE  ("binary" IS NULL OR "binary" = FALSE)
          AND  "content" IS NOT NULL
          AND  LENGTH(TRIM("content")) > 0
    )
)
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC, language
LIMIT 10;
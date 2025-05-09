WITH
-- keep only the candidate words
filtered AS (
    SELECT words
    FROM word_list
    WHERE substr(words,1,1) = 'r'
      AND length(words) BETWEEN 4 AND 5
),
-- numbers 1..5 (max length needed)
nums(n) AS (
    SELECT 1
    UNION ALL
    SELECT n+1 FROM nums WHERE n < 5
),
-- split each word into its characters
chars AS (
    SELECT f.words,
           substr(f.words,n,1) AS ch
    FROM filtered f
    JOIN nums
      ON n <= length(f.words)
),
-- build a case‑sensitive signature = its letters sorted
signatures AS (
    SELECT words,
           (SELECT group_concat(ch,'')
              FROM (SELECT ch
                      FROM chars c2
                     WHERE c2.words = c1.words
                     ORDER BY ch)
           ) AS sig
    FROM chars c1
    GROUP BY words
),
-- count how many words share the same signature
grp AS (
    SELECT words,
           sig,
           COUNT(*) OVER (PARTITION BY sig) AS group_size
    FROM signatures
)
SELECT words,
       group_size - 1 AS anagram_count          -- number of anagrams excluding itself
FROM   grp
WHERE  group_size > 1                           -- must have at least one anagram
GROUP  BY words, group_size
ORDER  BY words
LIMIT 10;
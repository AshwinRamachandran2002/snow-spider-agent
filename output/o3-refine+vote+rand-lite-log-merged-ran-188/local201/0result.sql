WITH RECURSIVE
-- 1. generate positions 1..length(word) for every 4-5-letter word
pos(word, p) AS (
    SELECT "words", 1
    FROM "word_list"
    WHERE length("words") BETWEEN 4 AND 5
    UNION ALL
    SELECT word, p + 1
    FROM pos
    WHERE p + 1 <= length(word)
),
-- 2. extract each character
chars AS (
    SELECT word,
           substr(word, p, 1) AS ch
    FROM pos
),
-- 3. build a sorted-letters signature for each word
signatures AS (
    SELECT word,
           group_concat(ch, '') AS sig
    FROM (
        SELECT word, ch
        FROM chars
        ORDER BY word, ch                -- sort characters alphabetically
    )
    GROUP BY word
),
-- 4. keep signatures that appear in more than one word (i.e., have anagrams)
sig_counts AS (
    SELECT sig,
           COUNT(*) AS anagram_count
    FROM signatures
    GROUP BY sig
    HAVING COUNT(*) > 1
),
-- 5. final filter: words 4-5 chars long, starting with 'r', having ≥1 anagram
qualified AS (
    SELECT s.word,
           sc.anagram_count
    FROM signatures AS s
    JOIN sig_counts  AS sc ON s.sig = sc.sig
    WHERE length(s.word) BETWEEN 4 AND 5
      AND s.word LIKE 'r%'              -- starts with 'r'
)
-- 6. return the first 10 alphabetically
SELECT word,
       anagram_count
FROM qualified
ORDER BY word
LIMIT 10;
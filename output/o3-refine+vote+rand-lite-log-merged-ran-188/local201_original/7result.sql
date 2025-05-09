WITH RECURSIVE
/* helper numbers 1..5 (max length we care about) */
nums(n) AS (
    VALUES (1)
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 5
),
/* candidate words that start with 'r' and are 4–5 letters long */
cand AS (
    SELECT words
    FROM word_list
    WHERE words LIKE 'r%' 
      AND LENGTH(words) BETWEEN 4 AND 5
),
/* split each word into individual characters */
chars AS (
    SELECT 
        c.words AS word,
        SUBSTR(c.words, n, 1) AS ch
    FROM cand AS c
    JOIN nums ON n <= LENGTH(c.words)
),
/* order the characters alphabetically for each word and build a signature */
signatures AS (
    SELECT 
        word,
        GROUP_CONCAT(ch, '') AS sig
    FROM (
        SELECT word, ch
        FROM chars
        ORDER BY word, ch          -- alphabetical per word
    )
    GROUP BY word
),
/* count how many words share the same signature */
sig_counts AS (
    SELECT 
        s1.word,
        (SELECT COUNT(*) 
           FROM signatures s2 
          WHERE s2.sig = s1.sig) AS grp_size
    FROM signatures AS s1
),
/* keep only words that have at least one anagram */
with_anagrams AS (
    SELECT 
        word,
        grp_size - 1 AS anagram_count  -- exclude the word itself
    FROM sig_counts
    WHERE grp_size > 1
)
SELECT 
    word,
    anagram_count
FROM with_anagrams
ORDER BY word
LIMIT 10;
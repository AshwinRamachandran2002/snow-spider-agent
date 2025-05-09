WITH
-- 1. words that meet the basic conditions
filtered AS (
    SELECT words AS word
    FROM word_list
    WHERE LENGTH(words) BETWEEN 4 AND 5
      AND SUBSTR(words,1,1) = 'r'
),
-- 2. split each word into one row per character
split(word, pos, ch, len) AS (
    SELECT word,
           1,
           SUBSTR(word,1,1),
           LENGTH(word)
    FROM filtered
    UNION ALL
    SELECT word,
           pos + 1,
           SUBSTR(word, pos + 1, 1),
           len
    FROM split
    WHERE pos < len
),
-- 3. build a sorted‑letter signature for every word
signatures AS (
    SELECT f.word,
           (SELECT GROUP_CONCAT(ch,'')
            FROM (
                SELECT ch
                FROM split s2
                WHERE s2.word = f.word
                ORDER BY ch
            )
           ) AS sig
    FROM filtered f
),
-- 4. keep only signatures that have at least one anagram partner
sig_groups AS (
    SELECT sig,
           COUNT(*) AS anagram_count
    FROM signatures
    GROUP BY sig
    HAVING COUNT(*) > 1
)
-- 5. final result
SELECT s.word,
       g.anagram_count
FROM signatures s
JOIN sig_groups g USING (sig)
ORDER BY s.word
LIMIT 10;
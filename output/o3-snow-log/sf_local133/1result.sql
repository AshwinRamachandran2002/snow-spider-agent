/* -----------------------------------------------------------
   1. Give every preference a weight (3, 2, or 1).
   2. Sum those weights per style => total weighted score.
   3. Work out the average of those totals over all styles
      that received at least one ranking.
   4. For every such style, show:
        • StyleID
        • StyleName
        • total weighted score
        • overall average score
        • absolute difference between the two
------------------------------------------------------------*/
WITH weighted_prefs AS (
    SELECT
        "StyleID",
        CASE
            WHEN "PreferenceSeq" = 1 THEN 3
            WHEN "PreferenceSeq" = 2 THEN 2
            WHEN "PreferenceSeq" = 3 THEN 1
            ELSE 0
        END AS pref_score
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
),
style_totals AS (
    SELECT
        "StyleID",
        SUM(pref_score) AS total_score
    FROM weighted_prefs
    GROUP BY "StyleID"
),
avg_tot AS (
    SELECT
        AVG(total_score) AS avg_total_score
    FROM style_totals
)
SELECT
    st."StyleID",
    ms."StyleName",
    st.total_score,
    at.avg_total_score,
    ABS(st.total_score - at.avg_total_score) AS abs_difference
FROM style_totals          st
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES ms
       ON st."StyleID" = ms."StyleID"
CROSS JOIN avg_tot         at
ORDER BY abs_difference DESC NULLS LAST;
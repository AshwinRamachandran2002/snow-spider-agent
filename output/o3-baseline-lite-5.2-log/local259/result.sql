WITH
player_info AS (
    SELECT player_id,
           player_name,
           batting_hand,
           bowling_skill
    FROM player
),

/* -------------------- ROLE (most frequent) -------------------- */
role_cnt AS (
    SELECT player_id,
           role,
           COUNT(*)                                                    AS cnt
    FROM player_match
    GROUP BY player_id, role
),
role_pref AS (
    SELECT player_id,
           role                                                        AS most_freq_role
    FROM (
        SELECT player_id,
               role,
               cnt,
               ROW_NUMBER() OVER (PARTITION BY player_id
                                  ORDER BY cnt DESC, role)            AS rn
        FROM role_cnt
    )
    WHERE rn = 1
),

/* -------------------- BATTING PART -------------------- */
batting_per_ball AS (
    SELECT b.striker                                                   AS player_id,
           b.match_id,
           s.runs_scored
    FROM   ball_by_ball      b
    JOIN   batsman_scored    s
           ON  s.match_id   = b.match_id
           AND s.over_id    = b.over_id
           AND s.ball_id    = b.ball_id
           AND s.innings_no = b.innings_no
),
batting_agg AS (
    SELECT player_id,
           SUM(runs_scored)                                            AS total_runs,
           COUNT(*)                                                    AS balls_faced
    FROM   batting_per_ball
    GROUP  BY player_id
),
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id)                                    AS matches_played
    FROM   player_match
    GROUP  BY player_id
),
dismissals AS (
    SELECT player_out                                                  AS player_id,
           COUNT(*)                                                    AS dismissals
    FROM   wicket_taken
    GROUP  BY player_id
),
score_per_match AS (
    SELECT player_id,
           match_id,
           SUM(runs_scored)                                            AS runs_in_match
    FROM   batting_per_ball
    GROUP  BY player_id, match_id
),
score_stats AS (
    SELECT player_id,
           MAX(runs_in_match)                                          AS highest_score,
           SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)       AS matches_30_plus,
           SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)       AS matches_50_plus,
           SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)       AS matches_100_plus
    FROM   score_per_match
    GROUP  BY player_id
),

/* -------------------- BOWLING PART -------------------- */
bowler_runs_per_ball AS (
    SELECT b.bowler                                                   AS player_id,
           b.match_id,
           b.innings_no,
           b.over_id,
           s.runs_scored
    FROM   ball_by_ball    b
    JOIN   batsman_scored  s
           ON  s.match_id   = b.match_id
           AND s.over_id    = b.over_id
           AND s.ball_id    = b.ball_id
           AND s.innings_no = b.innings_no
),
bowling_runs AS (
    SELECT player_id,
           SUM(runs_scored)                                            AS runs_conceded,
           COUNT(DISTINCT CAST(match_id AS TEXT) || '-' ||
                         CAST(innings_no AS TEXT) || '-' ||
                         CAST(over_id  AS TEXT))                       AS overs_bowled
    FROM   bowler_runs_per_ball
    GROUP  BY player_id
),
wickets_by_bowler AS (
    SELECT b.bowler                                                   AS player_id,
           COUNT(*)                                                   AS total_wickets
    FROM   wicket_taken w
    JOIN   ball_by_ball  b
           ON  w.match_id   = b.match_id
           AND w.over_id    = b.over_id
           AND w.ball_id    = b.ball_id
           AND w.innings_no = b.innings_no
    GROUP  BY player_id
),
bowler_match_wickets AS (
    SELECT b.bowler                                                   AS player_id,
           b.match_id,
           COUNT(*)                                                   AS wickets_in_match
    FROM   wicket_taken w
    JOIN   ball_by_ball  b
           ON  w.match_id   = b.match_id
           AND w.over_id    = b.over_id
           AND w.ball_id    = b.ball_id
           AND w.innings_no = b.innings_no
    GROUP  BY player_id, b.match_id
),
bowler_match_runs AS (
    SELECT player_id,
           match_id,
           SUM(runs_scored)                                           AS runs_conceded_in_match
    FROM   bowler_runs_per_ball
    GROUP  BY player_id, match_id
),
bowler_match_perf AS (
    SELECT COALESCE(r.player_id, w.player_id)                         AS player_id,
           COALESCE(r.match_id , w.match_id )                         AS match_id,
           COALESCE(w.wickets_in_match, 0)                            AS wickets_in_match,
           COALESCE(r.runs_conceded_in_match, 0)                      AS runs_conceded_in_match
    FROM   bowler_match_runs    r
    LEFT   JOIN bowler_match_wickets w
           ON  r.player_id = w.player_id AND r.match_id = w.match_id
),
best_bowling AS (
    SELECT player_id,
           printf('%d-%d', wickets_in_match, runs_conceded_in_match)  AS best_bowling
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY player_id
                                  ORDER BY wickets_in_match DESC,
                                           runs_conceded_in_match ASC) AS rn
        FROM   bowler_match_perf
    )
    WHERE rn = 1
)

/* -------------------- FINAL RESULT -------------------- */
SELECT p.player_id,
       p.player_name,
       COALESCE(rp.most_freq_role, '')                                AS most_freq_role,
       p.batting_hand,
       p.bowling_skill,
       COALESCE(ba.total_runs, 0)                                     AS total_runs,
       COALESCE(mp.matches_played, 0)                                 AS total_matches_played,
       COALESCE(d.dismissals, 0)                                      AS total_dismissals,
       CASE WHEN COALESCE(d.dismissals, 0) > 0
            THEN ROUND(1.0 * ba.total_runs / d.dismissals, 4)
       END                                                            AS batting_average,
       COALESCE(ss.highest_score, 0)                                  AS highest_score,
       COALESCE(ss.matches_30_plus, 0)                                AS matches_with_30_plus,
       COALESCE(ss.matches_50_plus, 0)                                AS matches_with_50_plus,
       COALESCE(ss.matches_100_plus, 0)                               AS matches_with_100_plus,
       COALESCE(ba.balls_faced, 0)                                    AS total_balls_faced,
       CASE WHEN COALESCE(ba.balls_faced, 0) > 0
            THEN ROUND(100.0 * ba.total_runs / ba.balls_faced, 4)
       END                                                            AS strike_rate,
       COALESCE(wb.total_wickets, 0)                                  AS total_wickets_taken,
       CASE WHEN COALESCE(br.overs_bowled, 0) > 0
            THEN ROUND(1.0 * br.runs_conceded / br.overs_bowled, 4)
       END                                                            AS economy_rate,
       bb.best_bowling
FROM   player_info      p
LEFT   JOIN role_pref          rp USING (player_id)
LEFT   JOIN batting_agg        ba USING (player_id)
LEFT   JOIN matches_played     mp USING (player_id)
LEFT   JOIN dismissals         d  USING (player_id)
LEFT   JOIN score_stats        ss USING (player_id)
LEFT   JOIN bowling_runs       br USING (player_id)
LEFT   JOIN wickets_by_bowler  wb USING (player_id)
LEFT   JOIN best_bowling       bb USING (player_id)
ORDER  BY p.player_id;
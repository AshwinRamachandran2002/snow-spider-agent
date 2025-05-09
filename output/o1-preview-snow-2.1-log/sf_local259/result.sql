WITH player_info AS (
    SELECT "player_id", "player_name", "batting_hand", "bowling_skill"
    FROM IPL.IPL.PLAYER
),
total_matches AS (
    SELECT "player_id", COUNT(DISTINCT "match_id") AS "Total_Matches_Played"
    FROM IPL.IPL.PLAYER_MATCH
    GROUP BY "player_id"
),
most_frequent_role AS (
    SELECT "player_id", "role" AS "Most_Frequent_Role"
    FROM (
        SELECT "player_id", "role",
               ROW_NUMBER() OVER (
                   PARTITION BY "player_id"
                   ORDER BY COUNT(*) DESC NULLS LAST
               ) AS rn
        FROM IPL.IPL.PLAYER_MATCH
        GROUP BY "player_id", "role"
    ) sub
    WHERE rn = 1
),
total_runs AS (
    SELECT b."striker" AS "player_id", SUM(s."runs_scored") AS "Total_Runs_Scored"
    FROM IPL.IPL.BATSMAN_SCORED s
    JOIN IPL.IPL.BALL_BY_BALL b
      ON s."match_id" = b."match_id" AND
         s."over_id" = b."over_id" AND
         s."ball_id" = b."ball_id" AND
         s."innings_no" = b."innings_no"
    GROUP BY b."striker"
),
total_balls_faced AS (
    SELECT "striker" AS "player_id", COUNT(*) AS "Total_Balls_Faced"
    FROM IPL.IPL.BALL_BY_BALL
    GROUP BY "striker"
),
total_dismissals AS (
    SELECT "player_out" AS "player_id", COUNT(*) AS "Total_Dismissals"
    FROM IPL.IPL.WICKET_TAKEN
    GROUP BY "player_out"
),
batting_average AS (
    SELECT tr."player_id",
           CASE WHEN td."Total_Dismissals" = 0 THEN NULL
                ELSE ROUND(tr."Total_Runs_Scored" / td."Total_Dismissals", 4)
           END AS "Batting_Average"
    FROM total_runs tr
    LEFT JOIN total_dismissals td ON tr."player_id" = td."player_id"
),
strike_rate AS (
    SELECT tr."player_id",
           CASE WHEN tbf."Total_Balls_Faced" = 0 THEN NULL
                ELSE ROUND((tr."Total_Runs_Scored" / tbf."Total_Balls_Faced") * 100, 4)
           END AS "Strike_Rate"
    FROM total_runs tr
    LEFT JOIN total_balls_faced tbf ON tr."player_id" = tbf."player_id"
),
highest_score AS (
    SELECT "player_id", MAX("match_runs") AS "Highest_Score_In_Single_Match"
    FROM (
        SELECT b."striker" AS "player_id", b."match_id", SUM(s."runs_scored") AS "match_runs"
        FROM IPL.IPL.BATSMAN_SCORED s
        JOIN IPL.IPL.BALL_BY_BALL b
          ON s."match_id" = b."match_id" AND
             s."over_id" = b."over_id" AND
             s."ball_id" = b."ball_id" AND
             s."innings_no" = b."innings_no"
        GROUP BY b."striker", b."match_id"
    ) sub
    GROUP BY "player_id"
),
matches_scored_over AS (
    SELECT "player_id",
           SUM(CASE WHEN "match_runs" > 30 THEN 1 ELSE 0 END) AS "Matches_Scored_Over_30",
           SUM(CASE WHEN "match_runs" > 50 THEN 1 ELSE 0 END) AS "Matches_Scored_Over_50",
           SUM(CASE WHEN "match_runs" > 100 THEN 1 ELSE 0 END) AS "Matches_Scored_Over_100"
    FROM (
        SELECT b."striker" AS "player_id", b."match_id", SUM(s."runs_scored") AS "match_runs"
        FROM IPL.IPL.BATSMAN_SCORED s
        JOIN IPL.IPL.BALL_BY_BALL b
          ON s."match_id" = b."match_id" AND
             s."over_id" = b."over_id" AND
             s."ball_id" = b."ball_id" AND
             s."innings_no" = b."innings_no"
        GROUP BY b."striker", b."match_id"
    ) sub
    GROUP BY "player_id"
),
total_wickets_taken AS (
    SELECT b."bowler" AS "player_id", COUNT(*) AS "Total_Wickets_Taken"
    FROM IPL.IPL.WICKET_TAKEN w
    JOIN IPL.IPL.BALL_BY_BALL b
      ON w."match_id" = b."match_id" AND
         w."over_id" = b."over_id" AND
         w."ball_id" = b."ball_id" AND
         w."innings_no" = b."innings_no"
    GROUP BY b."bowler"
),
bowling_stats AS (
    SELECT b."bowler" AS "player_id",
           SUM(s."runs_scored") AS "Total_Runs_Conceded",
           COUNT(*) AS "Total_Balls_Bowled",
           ROUND((SUM(s."runs_scored") / NULLIF(COUNT(*), 0)) * 6, 4) AS "Economy_Rate"
    FROM IPL.IPL.BATSMAN_SCORED s
    JOIN IPL.IPL.BALL_BY_BALL b
      ON s."match_id" = b."match_id" AND
         s."over_id" = b."over_id" AND
         s."ball_id" = b."ball_id" AND
         s."innings_no" = b."innings_no"
    GROUP BY b."bowler"
),
best_bowling AS (
    SELECT sub1."player_id",
           CONCAT(sub1."wickets_taken", '-', sub1."runs_conceded") AS "Best_Bowling_Performance"
    FROM (
        SELECT "player_id", "match_id", "wickets_taken", "runs_conceded",
               ROW_NUMBER() OVER (
                   PARTITION BY "player_id"
                   ORDER BY "wickets_taken" DESC NULLS LAST, "runs_conceded" ASC NULLS LAST
               ) AS rn
        FROM (
            SELECT b."bowler" AS "player_id", b."match_id",
                   COUNT(*) AS "wickets_taken",
                   SUM(s."runs_scored") AS "runs_conceded"
            FROM IPL.IPL.WICKET_TAKEN w
            JOIN IPL.IPL.BALL_BY_BALL b
              ON w."match_id" = b."match_id" AND
                 w."over_id" = b."over_id" AND
                 w."ball_id" = b."ball_id" AND
                 w."innings_no" = b."innings_no"
            LEFT JOIN IPL.IPL.BATSMAN_SCORED s
              ON b."match_id" = s."match_id" AND
                 b."over_id" = s."over_id" AND
                 b."ball_id" = s."ball_id" AND
                 b."innings_no" = s."innings_no"
            GROUP BY b."bowler", b."match_id"
        ) sub
    ) sub1
    WHERE sub1.rn = 1
)
SELECT pi."player_id" AS "Player_ID",
       pi."player_name" AS "Name",
       mfr."Most_Frequent_Role",
       pi."batting_hand" AS "Batting_Hand",
       pi."bowling_skill" AS "Bowling_Skill",
       tr."Total_Runs_Scored",
       tm."Total_Matches_Played",
       td."Total_Dismissals",
       ba."Batting_Average",
       hs."Highest_Score_In_Single_Match",
       mso."Matches_Scored_Over_30",
       mso."Matches_Scored_Over_50",
       mso."Matches_Scored_Over_100",
       tbf."Total_Balls_Faced",
       sr."Strike_Rate",
       twt."Total_Wickets_Taken",
       bs."Economy_Rate",
       bb."Best_Bowling_Performance"
FROM player_info pi
LEFT JOIN total_matches tm ON pi."player_id" = tm."player_id"
LEFT JOIN most_frequent_role mfr ON pi."player_id" = mfr."player_id"
LEFT JOIN total_runs tr ON pi."player_id" = tr."player_id"
LEFT JOIN total_dismissals td ON pi."player_id" = td."player_id"
LEFT JOIN batting_average ba ON pi."player_id" = ba."player_id"
LEFT JOIN highest_score hs ON pi."player_id" = hs."player_id"
LEFT JOIN matches_scored_over mso ON pi."player_id" = mso."player_id"
LEFT JOIN total_balls_faced tbf ON pi."player_id" = tbf."player_id"
LEFT JOIN strike_rate sr ON pi."player_id" = sr."player_id"
LEFT JOIN total_wickets_taken twt ON pi."player_id" = twt."player_id"
LEFT JOIN bowling_stats bs ON pi."player_id" = bs."player_id"
LEFT JOIN best_bowling bb ON pi."player_id" = bb."player_id"
ORDER BY pi."player_id" NULLS LAST;
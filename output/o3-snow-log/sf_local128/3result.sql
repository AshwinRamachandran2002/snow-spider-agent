WITH eligible_wins AS (
    SELECT 
        b."BowlerID",
        b."BowlerFirstName",
        b."BowlerLastName",
        bs."MatchID",
        bs."GameNumber",
        bs."HandiCapScore",
        t."TourneyDate",
        t."TourneyLocation"
    FROM BOWLINGLEAGUE.BOWLINGLEAGUE."BOWLER_SCORES"        bs
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE."BOWLERS"              b
          ON bs."BowlerID" = b."BowlerID"
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE."TOURNEY_MATCHES"      tm
          ON bs."MatchID" = tm."MatchID"
    JOIN BOWLINGLEAGUE.BOWLINGLEAGUE."TOURNAMENTS"          t
          ON tm."TourneyID" = t."TourneyID"
    WHERE bs."WonGame" = 1
      AND bs."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes',
                                  'Totem Lanes',
                                  'Bolero Lanes')
),
bowlers_all_three AS (
    SELECT "BowlerID"
    FROM   eligible_wins
    GROUP  BY "BowlerID"
    HAVING COUNT(DISTINCT "TourneyLocation") = 3          -- must have wins at all 3 venues
)
SELECT 
    ew."BowlerID",
    ew."BowlerFirstName",
    ew."BowlerLastName",
    ew."MatchID",
    ew."GameNumber",
    ew."HandiCapScore",
    ew."TourneyDate",
    ew."TourneyLocation"
FROM   eligible_wins      ew
JOIN   bowlers_all_three  b3
       ON ew."BowlerID" = b3."BowlerID"
ORDER BY 
    ew."BowlerID",
    ew."TourneyDate",
    ew."MatchID",
    ew."GameNumber";
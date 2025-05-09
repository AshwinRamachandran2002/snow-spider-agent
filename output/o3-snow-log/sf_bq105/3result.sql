/*  Traffic-fatality crashes attributed to driver distraction in 2015 & 2016
    – expressed per 100,000 residents (2010 Census population) and the five
      highest–rate states for each year                                             */

WITH pop AS (      -- 2010 Census population (embedded)
    SELECT column1::TEXT   AS "state_name",
           column2::NUMBER AS "population_2010"
    FROM VALUES
        ('Alabama',            4779736),
        ('Alaska',              710231),
        ('Arizona',            6392017),
        ('Arkansas',           2915918),
        ('California',        37253956),
        ('Colorado',           5029196),
        ('Connecticut',        3574097),
        ('Delaware',            897934),
        ('District of Columbia', 601723),
        ('Florida',           18801310),
        ('Georgia',            9687653),
        ('Hawaii',             1360301),
        ('Idaho',              1567582),
        ('Illinois',          12830632),
        ('Indiana',            6483802),
        ('Iowa',               3046355),
        ('Kansas',             2853118),
        ('Kentucky',           4339367),
        ('Louisiana',          4533372),
        ('Maine',              1328361),
        ('Maryland',           5773552),
        ('Massachusetts',      6547629),
        ('Michigan',           9883640),
        ('Minnesota',          5303925),
        ('Mississippi',        2967297),
        ('Missouri',           5988927),
        ('Montana',             989415),
        ('Nebraska',           1826341),
        ('Nevada',             2700551),
        ('New Hampshire',      1316470),
        ('New Jersey',         8791894),
        ('New Mexico',         2059179),
        ('New York',          19378102),
        ('North Carolina',     9535483),
        ('North Dakota',        672591),
        ('Ohio',              11536504),
        ('Oklahoma',           3751351),
        ('Oregon',             3831074),
        ('Pennsylvania',      12702379),
        ('Rhode Island',       1052567),
        ('South Carolina',     4625364),
        ('South Dakota',        814180),
        ('Tennessee',          6346105),
        ('Texas',             25145561),
        ('Utah',               2763885),
        ('Vermont',             625741),
        ('Virginia',           8001024),
        ('Washington',         6724540),
        ('West Virginia',      1852994),
        ('Wisconsin',          5686986),
        ('Wyoming',             563626)
), 

distract_2016 AS (          -- 2016 distraction-related fatal-crash counts
    SELECT
        "state_name",
        COUNT(*) AS "crashes_2016"
    FROM   NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2016
    WHERE  "driver_distracted_by_name" NOT IN ('Not Distracted',
                                               'Unknown if Distracted',
                                               'Not Reported')
    GROUP  BY "state_name"
), 

distract_2015 AS (          -- 2015 distraction-related fatal-crash counts
    SELECT
        ref."state_name",
        COUNT(*) AS "crashes_2015"
    FROM   NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2015 d15
    JOIN   NHTSA_TRAFFIC_FATALITIES_PLUS.UTILITY_US.US_STATES_AREA            ref
           ON LPAD(CAST(d15."state_number" AS STRING),2,'0') = ref."state_fips_code"
    WHERE  d15."driver_distracted_by_name" NOT IN ('Not Distracted',
                                                   'Unknown if Distracted',
                                                   'Not Reported')
    GROUP  BY ref."state_name"
), 

rates AS (                  -- per-100,000-population rates
    SELECT
        p."state_name",
        COALESCE(d15."crashes_2015",0)                                                    AS "crashes_2015",
        ROUND(COALESCE(d15."crashes_2015",0) * 100000.0 / p."population_2010", 4)         AS "rate_2015_per_100k",
        COALESCE(d16."crashes_2016",0)                                                    AS "crashes_2016",
        ROUND(COALESCE(d16."crashes_2016",0) * 100000.0 / p."population_2010", 4)         AS "rate_2016_per_100k"
    FROM   pop p
    LEFT  JOIN distract_2015 d15 ON p."state_name" = d15."state_name"
    LEFT  JOIN distract_2016 d16 ON p."state_name" = d16."state_name"
), 

ranked AS (                 -- rank states by their rates
    SELECT
        "state_name",
        "rate_2015_per_100k",
        DENSE_RANK() OVER (ORDER BY "rate_2015_per_100k" DESC) AS "rank_2015",
        "rate_2016_per_100k",
        DENSE_RANK() OVER (ORDER BY "rate_2016_per_100k" DESC) AS "rank_2016"
    FROM   rates
)

-- Top-five states (per year) by distraction-related fatal-crash rate
SELECT
    "state_name",
    "rate_2015_per_100k",
    "rank_2015",
    "rate_2016_per_100k",
    "rank_2016"
FROM   ranked
WHERE  "rank_2015" <= 5
   OR  "rank_2016" <= 5
ORDER  BY "rank_2015" NULLS LAST,
          "rank_2016" NULLS LAST,
          "state_name";
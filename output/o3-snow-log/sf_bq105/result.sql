/*--------------------------------------------------------------
  Distracted-driver crashes per 100,000 residents (2015 & 2016)
  – excludes “Not Distracted”, “Unknown if Distracted”, “Not Reported”
  – population denominator = 2010 decennial-census figures
----------------------------------------------------------------*/
WITH population_2010 (STATE_NAME , POP_2010) AS (       -- 2010 Census
    SELECT * FROM VALUES
        ('Alabama',4779736),   ('Alaska',710231),        ('Arizona',6392017),
        ('Arkansas',2915918),  ('California',37253956),  ('Colorado',5029196),
        ('Connecticut',3574097),('Delaware',897934),     ('District of Columbia',601723),
        ('Florida',18801310),  ('Georgia',9687653),      ('Hawaii',1360301),
        ('Idaho',1567582),     ('Illinois',12830632),    ('Indiana',6483802),
        ('Iowa',3046355),      ('Kansas',2853118),       ('Kentucky',4339367),
        ('Louisiana',4533372), ('Maine',1328361),        ('Maryland',5773552),
        ('Massachusetts',6547629),('Michigan',9883640), ('Minnesota',5303925),
        ('Mississippi',2967297),('Missouri',5988927),    ('Montana',989415),
        ('Nebraska',1826341),  ('Nevada',2700551),       ('New Hampshire',1316470),
        ('New Jersey',8791894),('New Mexico',2059179),   ('New York',19378102),
        ('North Carolina',9535483),('North Dakota',672591),('Ohio',11536504),
        ('Oklahoma',3751351),  ('Oregon',3831074),       ('Pennsylvania',12702379),
        ('Rhode Island',1052567),('South Carolina',4625364),('South Dakota',814180),
        ('Tennessee',6346105), ('Texas',25145561),       ('Utah',2763885),
        ('Vermont',625741),    ('Virginia',8001024),     ('Washington',6724540),
        ('West Virginia',1852994),('Wisconsin',5686986), ('Wyoming',563626),
        ('Puerto Rico',3725789)
),

/* 2016 – state names already present */
yr16 AS (
    SELECT  
        d16."state_name"        AS STATE_NAME,
        COUNT(*)                AS CNT_2016
    FROM    NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2016 d16
    WHERE   d16."driver_distracted_by_name" NOT IN ('Not Distracted',
                                                    'Unknown if Distracted',
                                                    'Not Reported')
    GROUP BY STATE_NAME
),

/* 2015 – translate state_number → name through FIPS table */
yr15 AS (
    SELECT  
        a."state_name"          AS STATE_NAME,
        COUNT(*)                AS CNT_2015
    FROM    NHTSA_TRAFFIC_FATALITIES_PLUS.NHTSA_TRAFFIC_FATALITIES.DISTRACT_2015 d15
    JOIN    NHTSA_TRAFFIC_FATALITIES_PLUS.UTILITY_US.US_STATES_AREA a
           ON LPAD(TO_VARCHAR(d15."state_number"),2,'0') = a."state_fips_code"
    WHERE   d15."driver_distracted_by_name" NOT IN ('Not Distracted',
                                                    'Unknown if Distracted',
                                                    'Not Reported')
    GROUP BY STATE_NAME
),

/* combine with population and calculate rates */
rates AS (
    SELECT
        p.STATE_NAME,
        COALESCE(y15.CNT_2015,0)                         AS ACCIDENTS_2015,
        ROUND(COALESCE(y15.CNT_2015,0)*100000.0/p.POP_2010,4) AS RATE_2015_PER_100K,
        COALESCE(y16.CNT_2016,0)                         AS ACCIDENTS_2016,
        ROUND(COALESCE(y16.CNT_2016,0)*100000.0/p.POP_2010,4) AS RATE_2016_PER_100K
    FROM population_2010 p
    LEFT JOIN yr15 y15 ON p.STATE_NAME = y15.STATE_NAME
    LEFT JOIN yr16 y16 ON p.STATE_NAME = y16.STATE_NAME
),

/* rank states for each year */
ranked AS (
    SELECT 
        r.*,
        RANK() OVER (ORDER BY RATE_2015_PER_100K DESC) AS RANK_2015,
        RANK() OVER (ORDER BY RATE_2016_PER_100K DESC) AS RANK_2016
    FROM   rates r
)

/* final report */
SELECT
    STATE_NAME,
    ACCIDENTS_2015,
    RATE_2015_PER_100K,
    ACCIDENTS_2016,
    RATE_2016_PER_100K,
    RANK_2015,
    RANK_2016,
    IFF(RANK_2015 <= 5,'★','') AS TOP5_2015,
    IFF(RANK_2016 <= 5,'★','') AS TOP5_2016
FROM   ranked
ORDER  BY STATE_NAME;
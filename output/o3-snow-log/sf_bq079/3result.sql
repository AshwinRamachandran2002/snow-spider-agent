WITH latest_eval AS (
    /* 1.  Most-recent EXPCURR evaluation group for every state  */
    SELECT 
        peg."state_code",
        MAX(peg."evaluation_group") AS latest_evaluation_group
    FROM USFS_FIA.USFS_FIA."POPULATION_EVALUATION_TYPE"  pet
    JOIN USFS_FIA.USFS_FIA."POPULATION_EVALUATION_GROUP" peg
          ON pet."evaluation_group_sequence_number" = peg."evaluation_group_sequence_number"
    WHERE pet."evaluation_type" = 'EXPCURR'
    GROUP BY peg."state_code"
),  

/* 2.  Acres (macro + sub) for those latest groups – timberland */
timber AS (
    SELECT  
        et."state_code",
        et."state_name",
        et."evaluation_group",
        SUM( COALESCE(et."macroplot_acres",0) + COALESCE(et."subplot_acres",0) )  AS total_acres
    FROM USFS_FIA.USFS_FIA."ESTIMATED_TIMBERLAND_ACRES" et
    JOIN latest_eval le
          ON  et."state_code"      = le."state_code"
          AND et."evaluation_group"= le.latest_evaluation_group
    GROUP BY et."state_code", et."state_name", et."evaluation_group"
), 

/* 3.  Acres (macro + sub) for those latest groups – forestland */
forest AS (
    SELECT  
        ef."state_code",
        ef."state_name",
        ef."evaluation_group",
        SUM( COALESCE(ef."macroplot_acres",0) + COALESCE(ef."subplot_acres",0) )  AS total_acres
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES" ef
    JOIN latest_eval le
          ON  ef."state_code"      = le."state_code"
          AND ef."evaluation_group"= le.latest_evaluation_group
    GROUP BY ef."state_code", ef."state_name", ef."evaluation_group"
), 

/* 4.  Pick the state with the greatest acreage in each category */
timber_max AS (
    SELECT * 
    FROM timber 
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_acres DESC NULLS LAST) = 1
), 
forest_max AS (
    SELECT * 
    FROM forest 
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_acres DESC NULLS LAST) = 1
)

/* 5.  Final answer */
SELECT 'TIMBERLAND' AS category,
       "state_code",
       "evaluation_group",
       "state_name",
       total_acres
FROM timber_max

UNION ALL

SELECT 'FORESTLAND' AS category,
       "state_code",
       "evaluation_group",
       "state_name",
       total_acres
FROM forest_max;
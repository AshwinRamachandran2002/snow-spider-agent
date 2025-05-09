/*  STEP-1 :  Tag every sample as CASE (=1, EAS) or CONTROL (=0, all others)        */
WITH sample_case_flag AS (
    SELECT  "Sample"                     AS sample_id ,
            IFF( "Super_Population" = 'EAS' , 1 , 0 ) AS is_case
    FROM    _1000_GENOMES._1000_GENOMES."SAMPLE_INFO"
),

/*  STEP-2 :  Explode the CALL array for every variant on chromosome 12             */
calls AS (
    SELECT  v."start" ,
            v."end"   ,
            f.value                AS call_obj        -- one object per sample
    FROM    _1000_GENOMES._1000_GENOMES."VARIANTS" v ,
            LATERAL FLATTEN( INPUT => v."call" ) f
    WHERE   v."reference_name" = '12'
),

/*  STEP-3 :  Pick genotypes and join with case/control information                 */
genotypes AS (
    SELECT  c."start" ,
            c."end"   ,
            c.call_obj:"call_set_name"::STRING                       AS sample_id ,
            NVL( c.call_obj:"genotype"[0]::INT , -1 )               AS g0 ,
            NVL( c.call_obj:"genotype"[1]::INT , -1 )               AS g1
    FROM    calls c
),

/*  STEP-4 :  Aggregate allele counts per variant for cases and controls            */
allele_counts AS (
    SELECT  g."start" ,
            g."end"   ,

            /* a : ALT alleles in cases   */
            SUM( CASE WHEN s.is_case = 1 THEN
                          ( CASE WHEN g.g0 = 1 THEN 1 ELSE 0 END ) +
                          ( CASE WHEN g.g1 = 1 THEN 1 ELSE 0 END )
                      ELSE 0 END )                                       AS a ,

            /* b : REF alleles in cases   */
            SUM( CASE WHEN s.is_case = 1 THEN
                          ( CASE WHEN g.g0 = 0 THEN 1 ELSE 0 END ) +
                          ( CASE WHEN g.g1 = 0 THEN 1 ELSE 0 END )
                      ELSE 0 END )                                       AS b ,

            /* c : ALT alleles in controls */
            SUM( CASE WHEN s.is_case = 0 THEN
                          ( CASE WHEN g.g0 = 1 THEN 1 ELSE 0 END ) +
                          ( CASE WHEN g.g1 = 1 THEN 1 ELSE 0 END )
                      ELSE 0 END )                                       AS c ,

            /* d : REF alleles in controls */
            SUM( CASE WHEN s.is_case = 0 THEN
                          ( CASE WHEN g.g0 = 0 THEN 1 ELSE 0 END ) +
                          ( CASE WHEN g.g1 = 0 THEN 1 ELSE 0 END )
                      ELSE 0 END )                                       AS d
    FROM        genotypes g
    INNER JOIN  sample_case_flag s
            ON  g.sample_id = s.sample_id
    GROUP BY    g."start" , g."end"
),

/*  STEP-5 :  Compute Yates-corrected χ² and expected counts                        */
chi_squared AS (
    SELECT  ac."start" ,
            ac."end"   ,
            ac.a , ac.b , ac.c , ac.d ,
            (ac.a + ac.b + ac.c + ac.d)                                  AS n ,

            /* expected counts for each cell */
            (ac.a + ac.b)*(ac.a + ac.c) / NULLIF( ac.a + ac.b + ac.c + ac.d , 0 )  AS e1 ,
            (ac.a + ac.b)*(ac.b + ac.d) / NULLIF( ac.a + ac.b + ac.c + ac.d , 0 )  AS e2 ,
            (ac.c + ac.d)*(ac.a + ac.c) / NULLIF( ac.a + ac.b + ac.c + ac.d , 0 )  AS e3 ,
            (ac.c + ac.d)*(ac.b + ac.d) / NULLIF( ac.a + ac.b + ac.c + ac.d , 0 )  AS e4 ,

            /* Yates continuity‐corrected χ² for 2×2 table */
            (   ( (ABS(ac.a * ac.d - ac.b * ac.c) - ( (ac.a + ac.b + ac.c + ac.d) / 2.0) )     -- numerator part
                  *
                  (ABS(ac.a * ac.d - ac.b * ac.c) - ( (ac.a + ac.b + ac.c + ac.d) / 2.0) )
                )
                *
                (ac.a + ac.b + ac.c + ac.d)
              )
              /
              NULLIF( (ac.a + ac.b) * (ac.c + ac.d) * (ac.a + ac.c) * (ac.b + ac.d) , 0 )
              AS chi_sq
    FROM   allele_counts ac
)

/*  STEP-6 :  Return variants that satisfy χ² ≥ 29.71679 and each expected ≥ 5      */
SELECT      "start" , "end" , chi_sq
FROM        chi_squared
WHERE       chi_sq >= 29.71679
        AND LEAST( e1 , e2 , e3 , e4 ) >= 5
ORDER BY    chi_sq DESC NULLS LAST;
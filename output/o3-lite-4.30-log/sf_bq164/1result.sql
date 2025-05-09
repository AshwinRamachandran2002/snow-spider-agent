SELECT
    "Filename"                     AS "Filename",
    "HTAN_Parent_Biospecimen_ID"   AS "HTAN Parent Biospecimen ID",
    "Component"                    AS "Component",
    "File_Format"                  AS "File Format",
    "entityId"                     AS "Entity ID",
    "Run_ID"                       AS "Run ID"
FROM (
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component","File_Format","entityId","Run_ID"
    FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT"
    
    UNION ALL
    
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component","File_Format","entityId","Run_ID"
    FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT"
    
    UNION ALL
    
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component","File_Format","entityId","Run_ID"
    FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT"
    
    UNION ALL
    
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component","File_Format","entityId","Run_ID"
    FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT"
    
    UNION ALL
    
    SELECT "Filename","HTAN_Parent_Biospecimen_ID","Component","File_Format","entityId","Run_ID"
    FROM "HTAN_2"."HTAN"."_10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT"
) AS all_visium_files
WHERE "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test';
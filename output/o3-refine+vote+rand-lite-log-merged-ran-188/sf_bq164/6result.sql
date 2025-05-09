WITH all_visium_files AS (

    -- Visium RNA-seq  Level 1  
    SELECT 
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN._10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL1_METADATA_CURRENT

    UNION ALL

    -- Visium RNA-seq  Level 2  
    SELECT 
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN._10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL2_METADATA_CURRENT

    UNION ALL

    -- Visium RNA-seq  Level 3  
    SELECT 
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN._10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL3_METADATA_CURRENT

    UNION ALL

    -- Visium RNA-seq  Level 4  
    SELECT 
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN._10XVISIUM_SPATIALTRANSCRIPTOMICS_SCRNASEQ_LEVEL4_METADATA_CURRENT

    UNION ALL

    -- Visium auxiliary files  
    SELECT 
        "Filename",
        "HTAN_Parent_Biospecimen_ID",
        "Component",
        "File_Format",
        "entityId",
        "Run_ID"
    FROM HTAN_2.HTAN._10XVISIUM_SPATIALTRANSCRIPTOMICS_AUXILIARYFILES_METADATA_CURRENT
)

SELECT DISTINCT
       "Filename",
       "HTAN_Parent_Biospecimen_ID",
       "Component",
       "File_Format",
       "entityId"      AS "Entity_ID",
       "Run_ID"
FROM   all_visium_files
WHERE  "Run_ID" = 'HT264P1-S1H2Fc2U1Z1Bs1-H2Bs2-Test'
ORDER BY "Component", "Filename";
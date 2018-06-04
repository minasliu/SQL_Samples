SET NEWPAGE 0;
SET SPACE 0;
SET LINESIZE 350;
SET PAGESIZE 0;
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF;
/*****************************************************************************/
/*     File Name     : PlanJust-BklgBegin.sql                                  */
/*     Description   : Gets Beginning Backlog for curr qtr & +1 for Plan*/
/*     Input tables  : kc_qtr_data                                      */
/*     Output file   : /home/minal/HardDrives/Queries/PlanJust-BklgBegin.txt*/
/*****************************************************************************/

VARIABLE currqtr CHAR(6);
VARIABLE prevqtr CHAR(6);

BEGIN
    SELECT fiscal_year_qtr
    INTO   :currqtr
    FROM   date_cd_v
    WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate,'MM/DD/YYYY');
  END;
/

BEGIN
    SELECT fiscal_year_qtr
    INTO   :prevqtr
    FROM   date_cd_v
    WHERE  TO_CHAR(calendar_date,'MM/DD/YYYY') = TO_CHAR(sysdate-91,'MM/DD/YYYY'); 
END;
/

SPOOL /home/minal/HardDrives/Queries/PlanJust-BklgBegin.txt
SET HEADING ON;

SELECT 	platform_name || '|' ||
	kc_desc || '|' ||
	fiscal_qtr || '|' ||
	sum(bklgbegin) bklgbegin
FROM	kc_qtr_data
WHERE	kc_type='STORAGE_HD'
AND	prod_no!=('R*')
AND	kc_cat='3.5" DISK'
AND	fiscal_qtr in (:currqtr,:prevqtr)
GROUP BY platform_name,
	kc_desc,
	fiscal_qtr
ORDER BY platform_name,
	kc_desc,
	fiscal_qtr;
	
SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM')
FROM dual;

SPOOL OFF;

EXIT;

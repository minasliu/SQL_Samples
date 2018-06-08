SET NEWPAGE 0;
SET SPACE 0;
SET LINESIZE 200;
SET PAGESIZE 0;
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF;
/*****************************************************************************/
/*     File Name     : PlanJust-CRDBooks.sql                                  */
/*     Description   : Gets crd bookings by customer by week for curr qtr & +1*/
/*     Input tables  : kc_qtr_wkly_data                                      */
/*     Output file   : /home/minal/HardDrives/Queries/PlanJust-CRDBooks.txt*/
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

SPOOL /home/minal/HardDrives/Queries/PlanJust-CRDBooksTest.txt
SET HEADING ON

SELECT 	platform_name  || '|' ||
	kc_desc  || '|' ||
	fiscal_qtr  || '|' ||
	fiscal_week  || '|' ||
	sum(crd_book_qty) crd_books
FROM	kc_qtr_wkly_data
WHERE	kc_type='STORAGE_HD'
AND	prod_no!=('R*')
AND	kc_cat='3.5" DISK'
AND	fiscal_qtr in (:currqtr,:prevqtr)
GROUP BY platform_name,
	kc_desc,
	fiscal_qtr,
	fiscal_week
ORDER BY platform_name,
	kc_desc,
	fiscal_qtr,
	fiscal_week;
	
SELECT TO_CHAR(sysdate,'Mon DD YYYY HH:MIAM')
FROM dual;

SPOOL OFF;

EXIT;

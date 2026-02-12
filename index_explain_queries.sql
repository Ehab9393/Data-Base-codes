/**********************************************************************
 * Description: 
 * This SQL script demonstrates creating and dropping indexes on 
 * various tables to analyze query performance using EXPLAIN. 
 * Tasks included:
 * 1. Index on APPLICANT(fname, lname) to optimize SELECT queries 
 *    filtering by first and last name.
 * 2. Index on POSITION(bonus) to optimize aggregate calculations 
 *    (AVG bonus).
 * 3. Index on APPLIES(pnumber) to optimize GROUP BY operations 
 *    counting applications per project.
 * The script also disables sequential scans and echoes all commands 
 * for analysis purposes. Indexes are removed after testing.
 **********************************************************************/

\set ECHO all
SET enable_seqscan=OFF;

/*task1 */
CREATE INDEX APPLICANT_fn_IDX ON APPLICANT(fname,lname);

EXPLAIN SELECT anumber, phone
FROM APPLICANT
WHERE fname IN ( 'Harry', 'James', 'Robin', 'Ivan' )
 AND lname = ( 'Bond' );
 
DROP INDEX APPLICANT_fn_IDX;

/*task2*/

CREATE INDEX POSITION_IDX ON position(bonus);

EXPLAIN SELECT Avg(bonus)
FROM position;

DROP INDEX POSITION_IDX;

/*task3*/
CREATE INDEX APPLIES_PN_IDX ON APPLIES(pnumber);

EXPLAIN SELECT pnumber, Count(*)
FROM APPLIES
 GROUP BY pnumber;
 
DROP INDEX APPLIES_PN_IDX;
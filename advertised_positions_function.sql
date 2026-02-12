/**********************************************************************
 * Description: 
 * This SQL script creates a PL/pgSQL function `advertised_positions`
 * that returns a semicolon-separated list of position titles advertised 
 * by a given employer. 
 *
 * The script performs the following:
 * 1. Defines the function `advertised_positions(ename_input TEXT)` 
 *    which iterates over all positions for a given employer and 
 *    concatenates their titles into a single string.
 * 2. Selects all employers with advertised positions and displays 
 *    their names along with the list of advertised positions.
 * 3. Selects employers who have no advertised positions.
 *
 * The function and queries are designed for PostgreSQL.
 **********************************************************************/

\set ECHO all

CREATE OR REPLACE FUNCTION advertised_positions(ename_input TEXT)
RETURNS TEXT AS
$$
DECLARE
    titles TEXT := '';
    title_var TEXT;
BEGIN
    FOR title_var IN 
        SELECT title FROM POSITION WHERE ename = ename_input ORDER BY title
    LOOP
        IF titles = '' THEN
            titles := title_var;
        ELSE
            titles := titles || '; ' || title_var;
        END IF;
    END LOOP;

    RETURN titles;
END;
$$
LANGUAGE plpgsql;


SELECT e.ename AS employer_name, advertised_positions(e.ename) AS advertised_positions
FROM EMPLOYER e
WHERE e.ename IN (SELECT DISTINCT p.ename FROM POSITION p)
ORDER BY e.ename;

SELECT e.ename AS employer_name
FROM EMPLOYER e
WHERE advertised_positions(e.ename) IS NULL OR advertised_positions(e.ename) = ''
ORDER BY e.ename;
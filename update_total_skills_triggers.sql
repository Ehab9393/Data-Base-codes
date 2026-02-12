/**********************************************************************
 * Description:
 * This SQL script manages the tracking of the total number of skills 
 * each applicant possesses in the APPLICANT table.
 *
 * It performs the following actions:
 * 1. Adds a new column `total_skills` to the APPLICANT table.
 * 2. Updates the `total_skills` column based on existing records in 
 *    the SPOSSESSED table.
 * 3. Creates a statement-level trigger `SkillEdit` using the function 
 *    `update_total_skills()` to update total skills after any INSERT or DELETE 
 *    operation on SPOSSESSED.
 * 4. Creates a row-level trigger `SkillEdit_row_trigger` using the function 
 *    `update_total_skills_row()` to update total skills immediately after each 
 *    row INSERT or DELETE in SPOSSESSED.
 *
 * This ensures that the `total_skills` column in APPLICANT remains accurate
 * and automatically updated.
 **********************************************************************/
 \set ECHO all

/*(1)*/
ALTER TABLE APPLICANT
ADD COLUMN total_skills DECIMAL(6);

/*(2)*/
UPDATE APPLICANT
	SET total_skills = (
	    SELECT COUNT(*) 
	    FROM SPOSSESSED
	    WHERE SPOSSESSED.anumber = APPLICANT.anumber
);

/*(3)*/
--create the stored function
CREATE OR REPLACE FUNCTION update_total_skills() 
RETURNS TRIGGER AS
$$
BEGIN
    
    UPDATE APPLICANT
    SET total_skills = (
        SELECT COUNT(*) 
        FROM SPOSSESSED
        WHERE SPOSSESSED.anumber = APPLICANT.anumber
    )
    WHERE anumber IN (
        SELECT DISTINCT anumber
        FROM SPOSSESSED
        WHERE anumber IS NOT NULL
    );

    RETURN NULL; 
END; 
$$ 
LANGUAGE plpgsql;

--create statement trigger
CREATE OR REPLACE TRIGGER SkillEdit  
    AFTER DELETE OR INSERT ON SPOSSESSED 
    FOR EACH STATEMENT 
    EXECUTE FUNCTION update_total_skills();

/*(4)*/
--create the stored function
CREATE OR REPLACE FUNCTION update_total_skills_row() 
RETURNS TRIGGER AS
$$
BEGIN
	-- For INSERT operations
    IF (TG_OP = 'INSERT') THEN
        UPDATE APPLICANT SET total_skills = (SELECT COUNT(*) 
            FROM SPOSSESSED
            WHERE anumber = NEW.anumber
        )
        WHERE anumber = NEW.anumber;
    
    -- For DELETE operations
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE APPLICANT SET total_skills = (SELECT COUNT(*) 
            FROM SPOSSESSED
            WHERE anumber = OLD.anumber
        )
        WHERE anumber = OLD.anumber;
    END IF;

    RETURN NULL; 
END;
$$
LANGUAGE plpgsql;

--create row trigger
CREATE OR REPLACE TRIGGER SkillEdit_row_trigger  
    AFTER INSERT OR DELETE ON SPOSSESSED
    FOR EACH ROW
    EXECUTE FUNCTION update_total_skills_row();

/**********************************************************************
 * Description:
 * Comprehensive SQL script demonstrating advanced SQL techniques:
 * - Table creation with constraints
 * - Data insertion
 * - Joins (INNER, LEFT)
 * - Aggregations and conditional aggregation
 * - CTEs
 * - Window functions (RANK, ROW_NUMBER, SUM OVER)
 * - Stored functions
 * - Triggers
 * - Views
 * - Indexes
 *
 * Scenario: Company Employee, Department, and Project Management
 **********************************************************************/

\set ECHO all

/*-------------------------------
  1. Create Tables with Constraints
--------------------------------*/

CREATE TABLE DEPARTMENT (
    dept_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    manager VARCHAR(50),
    budget DECIMAL(12,2) NOT NULL CHECK (budget > 0)
);

CREATE TABLE EMPLOYEE (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dept_id INT REFERENCES DEPARTMENT(dept_id),
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL CHECK (salary >= 0)
);

CREATE TABLE PROJECT (
    project_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    budget DECIMAL(12,2) NOT NULL CHECK (budget > 0),
    dept_id INT REFERENCES DEPARTMENT(dept_id)
);

CREATE TABLE ASSIGNMENT (
    emp_id INT REFERENCES EMPLOYEE(emp_id),
    project_id INT REFERENCES PROJECT(project_id),
    hours_worked DECIMAL(5,2) NOT NULL CHECK (hours_worked >= 0),
    PRIMARY KEY (emp_id, project_id)
);

/*-------------------------------
  2. Insert Sample Data
--------------------------------*/

INSERT INTO DEPARTMENT (name, manager, budget)
VALUES 
('IT', 'Alice Smith', 1000000),
('HR', 'Bob Johnson', 500000),
('Finance', 'Catherine Lee', 750000),
('Marketing', 'Daniel Kim', 600000);

INSERT INTO EMPLOYEE (first_name, last_name, dept_id, hire_date, salary)
VALUES
('John', 'Doe', 1, '2020-01-15', 80000),
('Jane', 'Smith', 1, '2019-03-10', 85000),
('Emily', 'Davis', 2, '2021-07-22', 60000),
('Michael', 'Brown', 3, '2018-11-30', 90000),
('Sarah', 'Wilson', 4, '2022-02-14', 55000),
('David', 'Clark', 1, '2020-06-05', 70000);

INSERT INTO PROJECT (title, budget, dept_id)
VALUES
('Website Redesign', 120000, 1),
('Recruitment Drive', 50000, 2),
('Financial Audit', 75000, 3),
('Social Media Campaign', 60000, 4),
('IT Security Upgrade', 150000, 1);

INSERT INTO ASSIGNMENT (emp_id, project_id, hours_worked)
VALUES
(1, 1, 120),
(2, 1, 100),
(6, 5, 80),
(3, 2, 90),
(4, 3, 110),
(5, 4, 70),
(2, 5, 60),
(1, 5, 50);

/*-------------------------------
  3. Aggregation & Conditional Aggregation
--------------------------------*/

-- Total hours worked per employee and average per project
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       d.name AS department,
       SUM(a.hours_worked) AS total_hours,
       COUNT(a.project_id) AS project_count,
       CASE WHEN COUNT(a.project_id) = 0 THEN 0
            ELSE SUM(a.hours_worked)/COUNT(a.project_id)
       END AS avg_hours_per_project
FROM EMPLOYEE e
LEFT JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
LEFT JOIN DEPARTMENT d ON e.dept_id = d.dept_id
GROUP BY e.emp_id, d.name
ORDER BY d.name, total_hours DESC;

-- Conditional aggregation: number of employees in each department by salary level
SELECT d.name AS department,
       COUNT(CASE WHEN e.salary > 80000 THEN 1 END) AS high_salary,
       COUNT(CASE WHEN e.salary BETWEEN 60000 AND 80000 THEN 1 END) AS medium_salary,
       COUNT(CASE WHEN e.salary < 60000 THEN 1 END) AS low_salary
FROM EMPLOYEE e
LEFT JOIN DEPARTMENT d ON e.dept_id = d.dept_id
GROUP BY d.name;

/*-------------------------------
  4. Window Functions
--------------------------------*/

-- Rank employees by salary within each department
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       d.name AS department,
       e.salary,
       RANK() OVER(PARTITION BY e.dept_id ORDER BY e.salary DESC) AS dept_salary_rank,
       SUM(e.salary) OVER(PARTITION BY e.dept_id) AS dept_total_salary
FROM EMPLOYEE e
JOIN DEPARTMENT d ON e.dept_id = d.dept_id
ORDER BY d.name, dept_salary_rank;

/*-------------------------------
  5. Subqueries and Joins
--------------------------------*/

-- Employees working on the most expensive project
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       p.title AS project_title,
       p.budget
FROM EMPLOYEE e
JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
JOIN PROJECT p ON a.project_id = p.project_id
WHERE p.budget = (SELECT MAX(budget) FROM PROJECT);

/*-------------------------------
  6. Stored Function Example
--------------------------------*/

CREATE OR REPLACE FUNCTION dept_salary_avg(dept_input INT)
RETURNS DECIMAL(10,2) AS
$$
DECLARE
    avg_salary DECIMAL(10,2);
BEGIN
    SELECT AVG(salary) INTO avg_salary
    FROM EMPLOYEE
    WHERE dept_id = dept_input;
    RETURN avg_salary;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
SELECT d.name, dept_salary_avg(d.dept_id) AS avg_salary
FROM DEPARTMENT d;

/*-------------------------------
  7. Trigger Example
--------------------------------*/

-- Create a trigger function to log salary changes
CREATE TABLE SALARY_LOG (
    log_id SERIAL PRIMARY KEY,
    emp_id INT,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.salary <> OLD.salary THEN
        INSERT INTO SALARY_LOG(emp_id, old_salary, new_salary)
        VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER salary_update_trigger
AFTER UPDATE OF salary ON EMPLOYEE
FOR EACH ROW
EXECUTE FUNCTION log_salary_change();

/*-------------------------------
  8. View Example
--------------------------------*/

CREATE OR REPLACE VIEW employee_summary AS
SELECT e.emp_id, e.first_name || ' ' || e.last_name AS employee_name,
       d.name AS department, e.salary,
       COALESCE(SUM(a.hours_worked),0) AS total_hours_worked
FROM EMPLOYEE e
LEFT JOIN DEPARTMENT d ON e.dept_id = d.dept_id
LEFT JOIN ASSIGNMENT a ON e.emp_id = a.emp_id
GROUP BY e.emp_id, d.name;

-- Select from the view
SELECT * FROM employee_summary;